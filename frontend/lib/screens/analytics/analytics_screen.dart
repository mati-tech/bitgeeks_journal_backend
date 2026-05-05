import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/analytics.dart';
import '../../providers/analytics_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/responsive.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/pnl_text.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();
    final pad = responsive(context, mobile: 16.0, tablet: 24.0, desktop: 32.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(pad, 24, pad, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Analytics',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton.outlined(
                onPressed: () => context.read<AnalyticsProvider>().loadAll(),
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabs,
          isScrollable: context.isMobile,
          tabAlignment: context.isMobile ? TabAlignment.start : TabAlignment.fill,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded), text: 'Overview'),
            Tab(icon: Icon(Icons.show_chart_rounded), text: 'Performance'),
            Tab(icon: Icon(Icons.layers_rounded), text: 'Breakdown'),
            Tab(icon: Icon(Icons.psychology_alt_rounded), text: 'Emotions'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _OverviewTab(provider: p, pad: pad),
              _PerformanceTab(provider: p, pad: pad),
              _BreakdownTab(provider: p, pad: pad),
              _EmotionsTab(provider: p, pad: pad),
            ],
          ),
        ),
      ],
    );
  }
}

// ────────────────────────── OVERVIEW ──────────────────────────

class _OverviewTab extends StatelessWidget {
  final AnalyticsProvider provider;
  final double pad;
  const _OverviewTab({required this.provider, required this.pad});

  @override
  Widget build(BuildContext context) {
    if (provider.loading && provider.summary == null) return const LoadingView();
    final s = provider.summary;
    if (s == null) {
      return ErrorView(
        message: provider.error ?? 'No analytics yet',
        onRetry: () => provider.loadAll(),
      );
    }
    final cols = responsive<int>(context, mobile: 2, tablet: 3, desktop: 4);

    return RefreshIndicator(
      onRefresh: () => provider.loadAll(),
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: 20),
        children: [
          GridView.count(
            crossAxisCount: cols,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: cols == 2 ? 1.4 : 1.5,
            children: [
              StatCard(
                label: 'TOTAL P&L',
                value: formatSignedMoney(s.totalPnl),
                valueColor: pnlColor(s.totalPnl),
                icon: Icons.account_balance_wallet_outlined,
                subtitle: '${s.closedTrades} closed',
              ),
              StatCard(
                label: 'WIN RATE',
                value: '${s.winRate.toStringAsFixed(1)}%',
                icon: Icons.flag_outlined,
                subtitle: '${s.winningTrades}W / ${s.losingTrades}L',
              ),
              StatCard(
                label: 'AVG WINNER',
                value: formatSignedMoney(s.avgWinner),
                valueColor: pnlColor(s.avgWinner),
                icon: Icons.trending_up,
              ),
              StatCard(
                label: 'AVG LOSER',
                value: formatSignedMoney(s.avgLoser),
                valueColor: pnlColor(s.avgLoser),
                icon: Icons.trending_down,
              ),
              StatCard(
                label: 'BEST TRADE',
                value: formatSignedMoney(s.bestTrade),
                valueColor: pnlColor(s.bestTrade),
                icon: Icons.emoji_events_outlined,
              ),
              StatCard(
                label: 'WORST TRADE',
                value: formatSignedMoney(s.worstTrade),
                valueColor: pnlColor(s.worstTrade),
                icon: Icons.heart_broken_outlined,
              ),
              StatCard(
                label: 'TOTAL FEES',
                value: formatMoney(s.totalFees),
                icon: Icons.receipt_long_outlined,
              ),
              StatCard(
                label: 'OPEN TRADES',
                value: s.openTrades.toString(),
                icon: Icons.pending_outlined,
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (s.closedTrades > 0) _winLossDonut(context, s),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _winLossDonut(BuildContext context, AnalyticsSummary s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Win / loss distribution'),
            SizedBox(
              height: 220,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        startDegreeOffset: -90,
                        centerSpaceRadius: 56,
                        sectionsSpace: 4,
                        sections: [
                          PieChartSectionData(
                            value: s.winningTrades.toDouble(),
                            color: AppColors.profit,
                            radius: 50,
                            title: '',
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: s.losingTrades.toDouble(),
                            color: AppColors.loss,
                            radius: 50,
                            title: '',
                            showTitle: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _legend(AppColors.profit, 'Wins · ${s.winningTrades}'),
                        const SizedBox(height: 8),
                        _legend(AppColors.loss, 'Losses · ${s.losingTrades}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color c, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: AppColors.textPrimary)),
      ],
    );
  }
}

// ────────────────────────── PERFORMANCE ──────────────────────────

class _PerformanceTab extends StatelessWidget {
  final AnalyticsProvider provider;
  final double pad;
  const _PerformanceTab({required this.provider, required this.pad});

  @override
  Widget build(BuildContext context) {
    if (provider.loading && provider.performance == null) return const LoadingView();
    final p = provider.performance;
    if (p == null) {
      return ErrorView(
        message: provider.error ?? 'No performance data',
        onRetry: () => provider.loadAll(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadAll(interval: provider.interval),
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: 20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cumulative P&L',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'day', label: Text('Day')),
                  ButtonSegment(value: 'week', label: Text('Week')),
                  ButtonSegment(value: 'month', label: Text('Month')),
                ],
                selected: {provider.interval},
                onSelectionChanged: (s) => provider.setInterval(s.first),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
              child: SizedBox(
                height: 320,
                child: p.points.isEmpty
                    ? const EmptyState(
                        icon: Icons.show_chart,
                        title: 'No closed trades yet',
                        subtitle: 'Close some trades to see your equity curve.',
                      )
                    : _CumulativeChart(points: p.points),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('P&L by ${p.interval}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 260,
                    child: p.points.isEmpty ? const SizedBox.shrink() : _BarPnlChart(points: p.points),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

class _CumulativeChart extends StatelessWidget {
  final List<PerformancePoint> points;
  const _CumulativeChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].cumulativePnl),
    ];
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final padding = (maxY - minY).abs() * 0.1 + 1;

    return LineChart(
      LineChartData(
        minY: minY - padding,
        maxY: maxY + padding,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.subtleBorder, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              getTitlesWidget: (v, _) => Text(
                formatMoney(v, compact: true),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (points.length / 6).clamp(1, 100).toDouble(),
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(points[i].period,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: AppColors.accent,
            barWidth: 2.5,
            dotData: FlDotData(
              show: points.length < 30,
              getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
                radius: 3,
                color: AppColors.accent,
                strokeWidth: 1.5,
                strokeColor: AppColors.background,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.25),
                  AppColors.accent.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceHigh,
            getTooltipItems: (spots) => spots.map((s) {
              final point = points[s.x.toInt()];
              return LineTooltipItem(
                '${point.period}\n${formatSignedMoney(point.cumulativePnl)}',
                const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _BarPnlChart extends StatelessWidget {
  final List<PerformancePoint> points;
  const _BarPnlChart({required this.points});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: AppColors.subtleBorder, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              getTitlesWidget: (v, _) => Text(
                formatMoney(v, compact: true),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (points.length / 6).clamp(1, 100).toDouble(),
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(points[i].period,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceHigh,
            getTooltipItem: (group, _, rod, __) {
              final p = points[group.x.toInt()];
              return BarTooltipItem(
                '${p.period}\n${formatSignedMoney(rod.toY)}',
                const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].pnl,
                  color: pnlColor(points[i].pnl),
                  width: 10,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ────────────────────────── BREAKDOWN ──────────────────────────

class _BreakdownTab extends StatelessWidget {
  final AnalyticsProvider provider;
  final double pad;
  const _BreakdownTab({required this.provider, required this.pad});

  @override
  Widget build(BuildContext context) {
    if (provider.loading && provider.byStrategy == null) return const LoadingView();
    final byStrategy = provider.byStrategy;
    final bySymbol = provider.bySymbol;
    if (byStrategy == null || bySymbol == null) {
      return ErrorView(message: provider.error ?? '—', onRetry: () => provider.loadAll());
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadAll(),
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: 20),
        children: [
          _GroupedTable(title: 'By strategy', rows: byStrategy.items),
          const SizedBox(height: 24),
          _GroupedTable(title: 'By symbol', rows: bySymbol.items),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

class _GroupedTable extends StatelessWidget {
  final String title;
  final List<GroupedRow> rows;
  const _GroupedTable({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No data', style: TextStyle(color: AppColors.textMuted))),
              )
            else
              Column(
                children: [
                  for (final r in rows) ...[
                    _row(context, r),
                    if (r != rows.last) const Divider(height: 14),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, GroupedRow r) {
    final maxAbsPnl = rows.map((e) => e.pnl.abs()).fold<double>(0, (a, b) => a > b ? a : b);
    final fraction = maxAbsPnl == 0 ? 0.0 : r.pnl.abs() / maxAbsPnl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(r.key, style: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: Text('${r.trades} trades',
                    textAlign: TextAlign.end,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 72,
                child: Text('${r.winRate.toStringAsFixed(0)}%',
                    textAlign: TextAlign.end,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: PnlPill(value: r.pnl),
                ),
              ),
            ],
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            minHeight: 4,
            value: fraction,
            backgroundColor: AppColors.surfaceHigh,
            color: pnlColor(r.pnl),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────── EMOTIONS ──────────────────────────

class _EmotionsTab extends StatelessWidget {
  final AnalyticsProvider provider;
  final double pad;
  const _EmotionsTab({required this.provider, required this.pad});

  @override
  Widget build(BuildContext context) {
    if (provider.loading && provider.emotional == null) return const LoadingView();
    final e = provider.emotional;
    if (e == null) {
      return ErrorView(message: provider.error ?? '—', onRetry: () => provider.loadAll());
    }

    if (e.items.isEmpty) {
      return const EmptyState(
        icon: Icons.psychology_alt_outlined,
        title: 'No emotional data yet',
        subtitle: 'Tag emotions on your trades to see how they correlate with P&L.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadAll(),
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: 20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('P&L by emotion',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('Correlate emotional state with trading outcomes.',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  for (final r in e.items) ...[
                    _row(context, r, e.items),
                    if (r != e.items.last) const Divider(height: 18),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, EmotionRow r, List<EmotionRow> all) {
    final maxAbs = all.map((e) => e.pnl.abs()).fold<double>(0, (a, b) => a > b ? a : b);
    final fraction = maxAbs == 0 ? 0.0 : r.pnl.abs() / maxAbs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                r.emotion,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 12),
            Text('${r.trades} trades · ${r.winRate.toStringAsFixed(0)}% win',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const Spacer(),
            PnlPill(value: r.pnl),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            minHeight: 4,
            value: fraction,
            backgroundColor: AppColors.surfaceHigh,
            color: pnlColor(r.pnl),
          ),
        ),
      ],
    );
  }
}
