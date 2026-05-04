import uuid
from datetime import datetime
from pathlib import Path

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy import desc
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.models import Trade, User
from app.schemas.trade import (
    TradeCreate,
    TradeListResponse,
    TradeOut,
    TradeUpdate,
)
from app.services.trade_service import apply_pnl
from app.utils.dependencies import get_current_user


router = APIRouter(prefix="/api/trades", tags=["trades"])

ALLOWED_IMAGE_TYPES = {"image/png", "image/jpeg", "image/webp"}


def _get_owned_trade(db: Session, user: User, trade_id: uuid.UUID) -> Trade:
    trade = db.query(Trade).filter(Trade.id == trade_id, Trade.user_id == user.id).first()
    if trade is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Trade not found")
    return trade


@router.post("", response_model=TradeOut, status_code=status.HTTP_201_CREATED)
def create_trade(
    payload: TradeCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> TradeOut:
    trade = Trade(user_id=current_user.id, **payload.model_dump())
    apply_pnl(trade)
    db.add(trade)
    db.commit()
    db.refresh(trade)
    return TradeOut.model_validate(trade)


@router.get("", response_model=TradeListResponse)
def list_trades(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    symbol: str | None = None,
    strategy: str | None = None,
    status_filter: str | None = Query(None, alias="status"),
    start_date: datetime | None = None,
    end_date: datetime | None = None,
) -> TradeListResponse:
    q = db.query(Trade).filter(Trade.user_id == current_user.id)

    if symbol:
        q = q.filter(Trade.symbol == symbol.strip().upper())
    if strategy:
        q = q.filter(Trade.strategy == strategy)
    if status_filter:
        q = q.filter(Trade.status == status_filter)
    if start_date:
        q = q.filter(Trade.entry_time >= start_date)
    if end_date:
        q = q.filter(Trade.entry_time <= end_date)

    total = q.count()
    items = q.order_by(desc(Trade.entry_time)).offset(offset).limit(limit).all()

    return TradeListResponse(
        items=[TradeOut.model_validate(t) for t in items],
        total=total,
        limit=limit,
        offset=offset,
    )


@router.get("/{trade_id}", response_model=TradeOut)
def get_trade(
    trade_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> TradeOut:
    trade = _get_owned_trade(db, current_user, trade_id)
    return TradeOut.model_validate(trade)


@router.put("/{trade_id}", response_model=TradeOut)
def update_trade(
    trade_id: uuid.UUID,
    payload: TradeUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> TradeOut:
    trade = _get_owned_trade(db, current_user, trade_id)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(trade, field, value)
    apply_pnl(trade)
    db.commit()
    db.refresh(trade)
    return TradeOut.model_validate(trade)


@router.delete("/{trade_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_trade(
    trade_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    trade = _get_owned_trade(db, current_user, trade_id)

    if trade.screenshot_url:
        local_path = trade.screenshot_url.lstrip("/")
        try:
            Path(local_path).unlink(missing_ok=True)
        except OSError:
            pass

    db.delete(trade)
    db.commit()


@router.post("/{trade_id}/screenshot", response_model=TradeOut)
async def upload_screenshot(
    trade_id: uuid.UUID,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> TradeOut:
    trade = _get_owned_trade(db, current_user, trade_id)

    if file.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail=f"Unsupported file type. Allowed: {sorted(ALLOWED_IMAGE_TYPES)}",
        )

    max_bytes = settings.MAX_UPLOAD_SIZE_MB * 1024 * 1024
    contents = await file.read()
    if len(contents) > max_bytes:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"File exceeds {settings.MAX_UPLOAD_SIZE_MB} MB limit",
        )

    ext = {"image/png": "png", "image/jpeg": "jpg", "image/webp": "webp"}[file.content_type]
    user_dir = Path(settings.UPLOAD_DIR) / "screenshots" / str(current_user.id)
    user_dir.mkdir(parents=True, exist_ok=True)

    filename = f"{trade_id}.{ext}"
    dest = user_dir / filename
    dest.write_bytes(contents)

    trade.screenshot_url = f"/{settings.UPLOAD_DIR.lstrip('./')}/screenshots/{current_user.id}/{filename}"
    db.commit()
    db.refresh(trade)
    return TradeOut.model_validate(trade)
