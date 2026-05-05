import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../utils/formatters.dart';

Color pnlColor(num? value) {
  if (value == null || value == 0) return AppColors.textSecondary;
  return value > 0 ? AppColors.profit : AppColors.loss;
}

class PnlText extends StatelessWidget {
  final num? value;
  final num? percentage;
  final TextStyle? style;
  final bool compact;

  const PnlText({
    super.key,
    required this.value,
    this.percentage,
    this.style,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.titleMedium!;
    final color = pnlColor(value);
    final money = formatSignedMoney(value, compact: compact);
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: money,
            style: base.copyWith(color: color, fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          if (percentage != null)
            TextSpan(
              text: '  ${formatSignedPercent(percentage)}',
              style: base.copyWith(
                color: color.withValues(alpha: 0.85),
                fontSize: (base.fontSize ?? 14) * 0.8,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );
  }
}

class PnlPill extends StatelessWidget {
  final num? value;
  final num? percentage;

  const PnlPill({super.key, required this.value, this.percentage});

  @override
  Widget build(BuildContext context) {
    final color = pnlColor(value);
    final bg = (value ?? 0) > 0
        ? AppColors.profitSoft
        : (value ?? 0) < 0
            ? AppColors.lossSoft
            : AppColors.surfaceHigh;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            (value ?? 0) >= 0 ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            formatSignedMoney(value, compact: true),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (percentage != null) ...[
            const SizedBox(width: 6),
            Text(
              formatSignedPercent(percentage),
              style: TextStyle(
                color: color.withValues(alpha: 0.75),
                fontSize: 12,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
