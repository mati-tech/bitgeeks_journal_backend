import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import desc
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Insight, Trade, User
from app.schemas.insight import InsightGenerateResponse, InsightOut
from app.services.ai_service import analyze_trades
from app.utils.dependencies import get_current_user


router = APIRouter(prefix="/api/insights", tags=["insights"])


@router.post("/generate", response_model=InsightGenerateResponse)
def generate_insights(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    lookback: int = Query(50, ge=5, le=200),
) -> InsightGenerateResponse:
    trades = (
        db.query(Trade)
        .filter(Trade.user_id == current_user.id)
        .order_by(desc(Trade.entry_time))
        .limit(lookback)
        .all()
    )

    if len(trades) < 5:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Need at least 5 trades to generate meaningful insights.",
        )

    try:
        new_insights = analyze_trades(trades)
    except RuntimeError as e:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"AI analysis failed: {e}",
        )

    saved: list[Insight] = []
    for ins in new_insights:
        record = Insight(user_id=current_user.id, **ins.model_dump())
        db.add(record)
        saved.append(record)
    db.commit()
    for r in saved:
        db.refresh(r)

    return InsightGenerateResponse(
        generated=len(saved),
        items=[InsightOut.model_validate(r) for r in saved],
    )


@router.get("", response_model=list[InsightOut])
def list_insights(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    limit: int = Query(50, ge=1, le=200),
) -> list[InsightOut]:
    items = (
        db.query(Insight)
        .filter(Insight.user_id == current_user.id)
        .order_by(desc(Insight.created_at))
        .limit(limit)
        .all()
    )
    return [InsightOut.model_validate(i) for i in items]


@router.get("/{insight_id}", response_model=InsightOut)
def get_insight(
    insight_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> InsightOut:
    insight = (
        db.query(Insight)
        .filter(Insight.id == insight_id, Insight.user_id == current_user.id)
        .first()
    )
    if insight is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Insight not found")
    return InsightOut.model_validate(insight)


@router.delete("/{insight_id}", status_code=status.HTTP_204_NO_CONTENT)
def dismiss_insight(
    insight_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    insight = (
        db.query(Insight)
        .filter(Insight.id == insight_id, Insight.user_id == current_user.id)
        .first()
    )
    if insight is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Insight not found")
    db.delete(insight)
    db.commit()
