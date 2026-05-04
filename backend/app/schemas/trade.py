import uuid
from datetime import datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator


TradeType = Literal["LONG", "SHORT"]
TradeStatus = Literal["open", "closed", "cancelled"]


class TradeBase(BaseModel):
    symbol: str = Field(max_length=50)
    trade_type: TradeType
    entry_price: Decimal = Field(gt=0)
    exit_price: Decimal | None = Field(default=None, gt=0)
    position_size: Decimal = Field(gt=0)
    leverage: int = Field(default=1, ge=1, le=125)
    entry_time: datetime
    exit_time: datetime | None = None
    fees: Decimal = Field(default=Decimal("0"), ge=0)
    strategy: str | None = Field(default=None, max_length=100)
    timeframe: str | None = Field(default=None, max_length=20)
    notes: str | None = None
    emotions: str | None = Field(default=None, max_length=255)
    status: TradeStatus = "open"

    @field_validator("symbol")
    @classmethod
    def normalize_symbol(cls, v: str) -> str:
        return v.strip().upper()


class TradeCreate(TradeBase):
    pass


class TradeUpdate(BaseModel):
    symbol: str | None = Field(default=None, max_length=50)
    trade_type: TradeType | None = None
    entry_price: Decimal | None = Field(default=None, gt=0)
    exit_price: Decimal | None = Field(default=None, gt=0)
    position_size: Decimal | None = Field(default=None, gt=0)
    leverage: int | None = Field(default=None, ge=1, le=125)
    entry_time: datetime | None = None
    exit_time: datetime | None = None
    fees: Decimal | None = Field(default=None, ge=0)
    strategy: str | None = Field(default=None, max_length=100)
    timeframe: str | None = Field(default=None, max_length=20)
    notes: str | None = None
    emotions: str | None = Field(default=None, max_length=255)
    status: TradeStatus | None = None


class TradeOut(TradeBase):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    pnl: Decimal | None
    pnl_percentage: Decimal | None
    screenshot_url: str | None
    created_at: datetime
    updated_at: datetime


class TradeListResponse(BaseModel):
    items: list[TradeOut]
    total: int
    limit: int
    offset: int
