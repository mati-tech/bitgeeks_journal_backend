import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/insight.dart';

class InsightCard extends StatelessWidget {
  final Insight insight;
  final VoidCallback? onDismiss;
  final VoidCallback? onShowTrades;

  const InsightCard({super.key, required this.insight, this.onDismiss, this.onShowTrades});

  Color _severityColor() {
    switch (insight.severity) {
      case InsightSeverity.critical:
        return AppColors.critical;
      case InsightSeverity.warning:
        return AppColors.warning;
      case InsightSeverity.info:
        return AppColors.info;
    }
  }

  IconData _severityIcon() {
    switch (insight.severity) {
      case InsightSeverity.critical:
        return Icons.warning_rounded;
      case InsightSeverity.warning:
        return Icons.error_outline_rounded;
      case InsightSeverity.info:
        return Icons.lightbulb_outline_rounded;
    }
  }

  IconData _typeIcon() {
    switch (insight.insightType) {
      case InsightType.psychological:
        return Icons.psychology_alt_outlined;
      case InsightType.pattern:
        return Icons.insights_outlined;
      case InsightType.strategy:
        return Icons.flag_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _severityColor();
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_severityIcon(), color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_typeIcon(), size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            insight.insightType.label.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.textMuted,
                              letterSpacing: 0.8,
                            ),
                          ),
                          if (insight.confidenceScore != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceHigh,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${insight.confidenceScore!.toStringAsFixed(0)}% conf',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        insight.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: AppColors.textMuted,
                    onPressed: onDismiss,
                    tooltip: 'Dismiss',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              insight.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            if (insight.relatedTrades.isNotEmpty && onShowTrades != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onShowTrades,
                icon: const Icon(Icons.list_alt_rounded, size: 16),
                label: Text('View ${insight.relatedTrades.length} related trade${insight.relatedTrades.length == 1 ? '' : 's'}'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
