import uuid
from datetime import datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


InsightType = Literal["pattern", "psychological", "strategy"]
InsightSeverity = Literal["info", "warning", "critical"]


class InsightCreate(BaseModel):
    insight_type: InsightType
    title: str = Field(max_length=255)
    description: str
    severity: InsightSeverity | None = None
    related_trades: list[uuid.UUID] | None = None
    confidence_score: Decimal | None = Field(default=None, ge=0, le=100)


class InsightOut(InsightCreate):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    created_at: datetime


class InsightGenerateResponse(BaseModel):
    generated: int
    items: list[InsightOut]
