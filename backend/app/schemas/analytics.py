from decimal import Decimal

from pydantic import BaseModel


class AnalyticsSummary(BaseModel):
    total_trades: int
    open_trades: int
    closed_trades: int
    winning_trades: int
    losing_trades: int
    win_rate: float
    total_pnl: Decimal
    total_fees: Decimal
    avg_pnl: Decimal | None
    avg_winner: Decimal | None
    avg_loser: Decimal | None
    best_trade: Decimal | None
    worst_trade: Decimal | None


class PerformancePoint(BaseModel):
    period: str
    trades: int
    pnl: Decimal
    cumulative_pnl: Decimal


class PerformanceSeries(BaseModel):
    interval: str
    points: list[PerformancePoint]


class GroupedPerformance(BaseModel):
    key: str
    trades: int
    pnl: Decimal
    win_rate: float


class GroupedPerformanceResponse(BaseModel):
    group_by: str
    items: list[GroupedPerformance]


class EmotionRow(BaseModel):
    emotion: str
    trades: int
    pnl: Decimal
    win_rate: float


class EmotionalAnalysis(BaseModel):
    items: list[EmotionRow]
