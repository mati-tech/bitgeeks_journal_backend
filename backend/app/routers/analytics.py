from collections import defaultdict
from datetime import datetime
from decimal import Decimal
from typing import Literal

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Trade, User
from app.schemas.analytics import (
    AnalyticsSummary,
    EmotionalAnalysis,
    EmotionRow,
    GroupedPerformance,
    GroupedPerformanceResponse,
    PerformancePoint,
    PerformanceSeries,
)
from app.utils.dependencies import get_current_user


router = APIRouter(prefix="/api/analytics", tags=["analytics"])


def _closed_trades(db: Session, user: User) -> list[Trade]:
    return (
        db.query(Trade)
        .filter(Trade.user_id == user.id, Trade.status == "closed", Trade.pnl.isnot(None))
        .all()
    )


@router.get("/summary", response_model=AnalyticsSummary)
def summary(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> AnalyticsSummary:
    all_trades = db.query(Trade).filter(Trade.user_id == current_user.id).all()
    closed = [t for t in all_trades if t.status == "closed" and t.pnl is not None]
    pnls = [Decimal(t.pnl) for t in closed]

    winners = [p for p in pnls if p > 0]
    losers = [p for p in pnls if p < 0]
    total_pnl = sum(pnls, Decimal("0"))
    total_fees = sum((Decimal(t.fees or 0) for t in all_trades), Decimal("0"))

    win_rate = (len(winners) / len(closed) * 100) if closed else 0.0

    return AnalyticsSummary(
        total_trades=len(all_trades),
        open_trades=sum(1 for t in all_trades if t.status == "open"),
        closed_trades=len(closed),
        winning_trades=len(winners),
        losing_trades=len(losers),
        win_rate=round(win_rate, 2),
        total_pnl=total_pnl,
        total_fees=total_fees,
        avg_pnl=(sum(pnls, Decimal("0")) / len(pnls)) if pnls else None,
        avg_winner=(sum(winners, Decimal("0")) / len(winners)) if winners else None,
        avg_loser=(sum(losers, Decimal("0")) / len(losers)) if losers else None,
        best_trade=max(pnls) if pnls else None,
        worst_trade=min(pnls) if pnls else None,
    )


@router.get("/performance", response_model=PerformanceSeries)
def performance(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    interval: Literal["day", "week", "month"] = Query("day"),
    start_date: datetime | None = None,
    end_date: datetime | None = None,
) -> PerformanceSeries:
    q = db.query(Trade).filter(
        Trade.user_id == current_user.id,
        Trade.status == "closed",
        Trade.exit_time.isnot(None),
    )
    if start_date:
        q = q.filter(Trade.exit_time >= start_date)
    if end_date:
        q = q.filter(Trade.exit_time <= end_date)

    trades = q.all()

    def bucket_key(dt: datetime) -> str:
        if interval == "day":
            return dt.strftime("%Y-%m-%d")
        if interval == "week":
            iso = dt.isocalendar()
            return f"{iso.year}-W{iso.week:02d}"
        return dt.strftime("%Y-%m")

    buckets: dict[str, list[Decimal]] = defaultdict(list)
    for t in trades:
        if t.pnl is not None:
            buckets[bucket_key(t.exit_time)].append(Decimal(t.pnl))

    cumulative = Decimal("0")
    points: list[PerformancePoint] = []
    for key in sorted(buckets):
        pnl = sum(buckets[key], Decimal("0"))
        cumulative += pnl
        points.append(
            PerformancePoint(
                period=key,
                trades=len(buckets[key]),
                pnl=pnl,
                cumulative_pnl=cumulative,
            )
        )

    return PerformanceSeries(interval=interval, points=points)


def _grouped(trades: list[Trade], key_fn) -> list[GroupedPerformance]:
    groups: dict[str, list[Decimal]] = defaultdict(list)
    for t in trades:
        key = key_fn(t)
        if key is None:
            key = "(unspecified)"
        groups[key].append(Decimal(t.pnl))

    out: list[GroupedPerformance] = []
    for key, pnls in groups.items():
        wins = sum(1 for p in pnls if p > 0)
        out.append(
            GroupedPerformance(
                key=key,
                trades=len(pnls),
                pnl=sum(pnls, Decimal("0")),
                win_rate=round(wins / len(pnls) * 100, 2),
            )
        )
    out.sort(key=lambda r: r.pnl, reverse=True)
    return out


@router.get("/by-strategy", response_model=GroupedPerformanceResponse)
def by_strategy(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> GroupedPerformanceResponse:
    items = _grouped(_closed_trades(db, current_user), lambda t: t.strategy)
    return GroupedPerformanceResponse(group_by="strategy", items=items)


@router.get("/by-symbol", response_model=GroupedPerformanceResponse)
def by_symbol(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> GroupedPerformanceResponse:
    items = _grouped(_closed_trades(db, current_user), lambda t: t.symbol)
    return GroupedPerformanceResponse(group_by="symbol", items=items)


@router.get("/emotional-analysis", response_model=EmotionalAnalysis)
def emotional_analysis(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> EmotionalAnalysis:
    trades = _closed_trades(db, current_user)
    buckets: dict[str, list[Decimal]] = defaultdict(list)
    for t in trades:
        raw = (t.emotions or "").strip()
        if not raw:
            buckets["(unspecified)"].append(Decimal(t.pnl))
            continue
        for tag in [s.strip().lower() for s in raw.split(",") if s.strip()]:
            buckets[tag].append(Decimal(t.pnl))

    rows: list[EmotionRow] = []
    for tag, pnls in buckets.items():
        wins = sum(1 for p in pnls if p > 0)
        rows.append(
            EmotionRow(
                emotion=tag,
                trades=len(pnls),
                pnl=sum(pnls, Decimal("0")),
                win_rate=round(wins / len(pnls) * 100, 2),
            )
        )
    rows.sort(key=lambda r: r.pnl, reverse=True)
    return EmotionalAnalysis(items=rows)
