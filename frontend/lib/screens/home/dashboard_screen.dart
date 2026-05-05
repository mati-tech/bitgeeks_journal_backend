import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/insights_provider.dart';
import '../../providers/trades_provider.dart';
import '../../services/trade_service.dart';
import '../../utils/formatters.dart';
import '../../utils/responsive.dart';
import '../../widgets/insight_card.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/pnl_text.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/trade_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<AnalyticsProvider>().loadSummary(),
      context.read<TradesProvider>().load(filters: const TradeListFilters(limit: 5)),
      context.read<InsightsProvider>().load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final analytics = context.watch<AnalyticsProvider>();
    final trades = context.watch<TradesProvider>();
    final insights = context.watch<InsightsProvider>();

    final twoColumn = context.isDesktop;
    final pad = responsive(context, mobile: 16.0, tablet: 24.0, desktop: 40.0);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: 24),
        children: [
          _greeting(context, auth),
          const SizedBox(height: 24),
          if (twoColumn)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _statsGrid(context, analytics),
                      const SizedBox(height: 28),
                      _recentTradesSection(context, trades),
                    ],
                  ),
                ),
                const SizedBox(width: 28),
                Expanded(
                  flex: 4,
                  child: _insightsSection(context, insights),
                ),
              ],
            )
          else ...[
            _statsGrid(context, analytics),
            const SizedBox(height: 32),
            _recentTradesSection(context, trades),
            const SizedBox(height: 32),
            _insightsSection(context, insights),
          ],
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _recentTradesSection(BuildContext context, TradesProvider trades) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Recent trades',
          subtitle: trades.total > 0 ? '${trades.total} total trades logged' : null,
          action: TextButton.icon(
            onPressed: () => context.go('/trades'),
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('View all'),
          ),
        ),
        if (trades.loading && trades.trades.isEmpty)
          const SizedBox(height: 80, child: LoadingView())
        else if (trades.trades.isEmpty)
          _emptyTrades(context)
        else
          Column(
            children: [
              for (final trade in trades.trades.take(5)) ...[
                TradeCard(
                  trade: trade,
                  onTap: () => context.go('/trades/${trade.id}'),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
      ],
    );
  }

  Widget _insightsSection(BuildContext context, InsightsProvider insights) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Latest insights',
          subtitle: insights.items.isEmpty ? 'No insights yet — generate them once you have 5+ trades' : null,
          action: insights.items.isNotEmpty
              ? TextButton.icon(
                  onPressed: () => context.go('/insights'),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('View all'),
                )
              : null,
        ),
        if (insights.loading && insights.items.isEmpty)
          const SizedBox(height: 80, child: LoadingView())
        else if (insights.items.isEmpty)
          _emptyInsights(context)
        else
          Column(
            children: [
              for (final insight in insights.items.take(3)) ...[
                InsightCard(insight: insight),
                const SizedBox(height: 10),
              ],
            ],
          ),
      ],
    );
  }

  Widget _greeting(BuildContext context, AuthProvider auth) {
    final name = auth.user?.fullName ?? auth.user?.email.split('@').first ?? 'trader';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, $name',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Here\'s how your trading is going.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (!context.isMobile)
          FilledButton.icon(
            onPressed: () => context.go('/trades/new'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Log a trade'),
          ),
      ],
    );
  }

  Widget _statsGrid(BuildContext context, AnalyticsProvider a) {
    final s = a.summary;
    // Desktop uses a two-column body layout, so the stats grid lives in the
    // narrower left column — 2x2 reads better there than 4x1.
    final cols = responsive<int>(context, mobile: 2, tablet: 4, desktop: 2);

    Widget summaryCard({
      required String label,
      required String value,
      String? subtitle,
      Color? color,
      IconData? icon,
      Widget? trailing,
    }) =>
        StatCard(label: label, value: value, subtitle: subtitle, valueColor: color, icon: icon, trailing: trailing);

    final children = <Widget>[
      summaryCard(
        label: 'TOTAL P&L',
        value: s == null ? '—' : formatSignedMoney(s.totalPnl),
        subtitle: s == null ? null : '${s.closedTrades} closed trades',
        color: pnlColor(s?.totalPnl),
        icon: Icons.account_balance_wallet_outlined,
      ),
      summaryCard(
        label: 'WIN RATE',
        value: s == null ? '—' : '${s.winRate.toStringAsFixed(1)}%',
        subtitle: s == null ? null : '${s.winningTrades}W / ${s.losingTrades}L',
        icon: Icons.flag_outlined,
      ),
      summaryCard(
        label: 'BEST TRADE',
        value: s == null ? '—' : formatSignedMoney(s.bestTrade),
        color: pnlColor(s?.bestTrade),
        icon: Icons.trending_up,
      ),
      summaryCard(
        label: 'WORST TRADE',
        value: s == null ? '—' : formatSignedMoney(s.worstTrade),
        color: pnlColor(s?.worstTrade),
        icon: Icons.trending_down,
      ),
    ];

    final tileHeight = responsive<double>(context, mobile: 138, tablet: 130, desktop: 130);
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: children.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: tileHeight,
      ),
      itemBuilder: (_, i) => children[i],
    );
  }

  Widget _emptyTrades(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(Icons.candlestick_chart_outlined, size: 36, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('No trades yet', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text(
              'Log your first trade to start tracking performance.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go('/trades/new'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Log a trade'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyInsights(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome_outlined, color: AppColors.accent),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Generate AI insights once you have 5+ trades to find patterns and blind spots.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/insights'),
              child: const Text('Open'),
            ),
          ],
        ),
      ),
    );
  }
}
