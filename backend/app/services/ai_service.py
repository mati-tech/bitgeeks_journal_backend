import json
import re
from decimal import Decimal

from anthropic import Anthropic

from app.config import settings
from app.models import Trade
from app.schemas.insight import InsightCreate


CLAUDE_MODEL = "claude-sonnet-4-6"

SYSTEM_PROMPT = (
    "You are a professional trading psychologist and analyst. "
    "Analyze trades and produce concise, actionable insights. "
    "Always respond with a single JSON array — no prose around it."
)

USER_PROMPT_TEMPLATE = """Analyze these {n} trades and identify:

1. Losing patterns: behaviors/conditions correlating with losses (time, leverage, emotions, symbol, timeframe).
2. Winning patterns: setups that work best for this trader.
3. Psychological issues: FOMO, revenge trading, overconfidence, hesitation.
4. Risk management issues: position sizing, leverage, stop placement, exits.

Trades data:
{trades_json}

Return a JSON array of objects with this exact shape:
[
  {{
    "insight_type": "psychological" | "pattern" | "strategy",
    "title": "Brief title (<= 60 chars)",
    "description": "2-3 sentences, specific and actionable",
    "severity": "info" | "warning" | "critical",
    "confidence_score": 0-100,
    "related_trade_ids": ["uuid", ...]
  }}
]

Focus on specific, actionable findings. Avoid generic advice. Cite the trades that support each insight via their UUIDs."""


def _serialize_trade(t: Trade) -> dict:
    return {
        "id": str(t.id),
        "symbol": t.symbol,
        "type": t.trade_type,
        "entry_price": float(t.entry_price),
        "exit_price": float(t.exit_price) if t.exit_price is not None else None,
        "position_size": float(t.position_size),
        "leverage": t.leverage,
        "pnl": float(t.pnl) if t.pnl is not None else None,
        "pnl_pct": float(t.pnl_percentage) if t.pnl_percentage is not None else None,
        "strategy": t.strategy,
        "timeframe": t.timeframe,
        "emotions": t.emotions,
        "entry_time": t.entry_time.isoformat() if t.entry_time else None,
        "exit_time": t.exit_time.isoformat() if t.exit_time else None,
        "status": t.status,
    }


def _extract_json_array(text: str) -> list[dict]:
    """Claude usually returns clean JSON; tolerate accidental code-fence wrapping."""
    text = text.strip()
    fenced = re.search(r"```(?:json)?\s*(\[.*?\])\s*```", text, re.DOTALL)
    if fenced:
        text = fenced.group(1)
    bracket = text.find("[")
    if bracket > 0:
        text = text[bracket:]
    return json.loads(text)


def analyze_trades(trades: list[Trade]) -> list[InsightCreate]:
    if not settings.ANTHROPIC_API_KEY:
        raise RuntimeError(
            "ANTHROPIC_API_KEY is not configured. Set it in .env to enable AI insights."
        )
    if not trades:
        return []

    client = Anthropic(api_key=settings.ANTHROPIC_API_KEY)

    payload = [_serialize_trade(t) for t in trades]
    user_prompt = USER_PROMPT_TEMPLATE.format(
        n=len(trades),
        trades_json=json.dumps(payload, indent=2, default=str),
    )

    response = client.messages.create(
        model=CLAUDE_MODEL,
        max_tokens=4096,
        system=SYSTEM_PROMPT,
        messages=[{"role": "user", "content": user_prompt}],
    )

    text = "".join(block.text for block in response.content if block.type == "text")
    raw_insights = _extract_json_array(text)

    insights: list[InsightCreate] = []
    for item in raw_insights:
        try:
            related_ids = item.get("related_trade_ids") or []
            insights.append(
                InsightCreate(
                    insight_type=item["insight_type"],
                    title=item["title"][:255],
                    description=item["description"],
                    severity=item.get("severity", "info"),
                    related_trades=related_ids if related_ids else None,
                    confidence_score=Decimal(str(item["confidence_score"]))
                    if item.get("confidence_score") is not None
                    else None,
                )
            )
        except (KeyError, ValueError):
            continue
    return insights
