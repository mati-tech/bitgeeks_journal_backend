import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/trade.dart';
import '../utils/formatters.dart';
import 'pnl_text.dart';

class TradeCard extends StatelessWidget {
  final Trade trade;
  final VoidCallback? onTap;

  const TradeCard({super.key, required this.trade, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLong = trade.tradeType == TradeType.long;
    final accent = isLong ? AppColors.profit : AppColors.loss;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 56,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                trade.symbol,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              _typePill(trade.tradeType),
                              if (trade.leverage > 1) _smallChip('${trade.leverage}x'),
                              if (!trade.isClosed) _smallChip('OPEN', color: AppColors.warning),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        PnlPill(value: trade.pnl, percentage: trade.pnlPercentage),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: [
                        _meta(Icons.login, formatMoney(trade.entryPrice, compact: true)),
                        if (trade.exitPrice != null)
                          _meta(Icons.logout, formatMoney(trade.exitPrice, compact: true)),
                        _meta(Icons.event, formatDateTime(trade.entryTime)),
                        if (trade.duration != null)
                          _meta(Icons.timer_outlined, formatDuration(trade.duration)),
                        if (trade.strategy != null)
                          _meta(Icons.layers_outlined, trade.strategy!),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typePill(TradeType type) {
    final isLong = type == TradeType.long;
    final color = isLong ? AppColors.profit : AppColors.loss;
    final bg = isLong ? AppColors.profitSoft : AppColors.lossSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        type.label.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.5),
      ),
    );
  }

  Widget _smallChip(String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color?.withValues(alpha: 0.3) ?? AppColors.border),
      ),
      child: Text(
        text,
        style: TextStyle(color: color ?? AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
