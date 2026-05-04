from decimal import Decimal

from app.models import Trade


def compute_pnl(trade: Trade) -> tuple[Decimal | None, Decimal | None]:
    """Return (pnl_usd, pnl_pct). Both None if the trade isn't closed."""
    if trade.exit_price is None or trade.status != "closed":
        return None, None

    entry = Decimal(trade.entry_price)
    exit_ = Decimal(trade.exit_price)
    size = Decimal(trade.position_size)
    fees = Decimal(trade.fees or 0)

    direction = Decimal("1") if trade.trade_type == "LONG" else Decimal("-1")
    price_diff = (exit_ - entry) * direction

    pnl_usd = (price_diff * size) - fees
    pnl_pct = (price_diff / entry) * Decimal(trade.leverage or 1) * Decimal("100")

    return pnl_usd.quantize(Decimal("0.0001")), pnl_pct.quantize(Decimal("0.0001"))


def apply_pnl(trade: Trade) -> None:
    """Mutate trade in-place to set pnl/pnl_percentage based on current state."""
    pnl, pct = compute_pnl(trade)
    trade.pnl = pnl
    trade.pnl_percentage = pct
