import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/trade.dart';
import '../../providers/trades_provider.dart';
import '../../services/trade_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/trade_card.dart';

class TradesListScreen extends StatefulWidget {
  const TradesListScreen({super.key});

  @override
  State<TradesListScreen> createState() => _TradesListScreenState();
}

class _TradesListScreenState extends State<TradesListScreen> {
  final _searchCtrl = TextEditingController();
  TradeStatus? _statusFilter;
  String? _strategyFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TradesProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilters() {
    context.read<TradesProvider>().load(
          filters: TradeListFilters(
            symbol: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
            status: _statusFilter,
            strategy: _strategyFilter,
          ),
        );
  }

  void _clear() {
    setState(() {
      _searchCtrl.clear();
      _statusFilter = null;
      _strategyFilter = null;
    });
    context.read<TradesProvider>().load(filters: const TradeListFilters());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TradesProvider>();
    final pad = responsive(context, mobile: 16.0, tablet: 24.0, desktop: 32.0);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(pad, 24, pad, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Trades',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!context.isMobile)
                FilledButton.icon(
                  onPressed: () => context.go('/trades/new'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New trade'),
                ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: _filtersBar(),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => context.read<TradesProvider>().load(filters: provider.filters),
            child: _body(provider, pad),
          ),
        ),
      ],
    );
  }

  Widget _filtersBar() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Filter by symbol (e.g. BTC/USDT)',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        setState(_searchCtrl.clear);
                        _applyFilters();
                      },
                    ),
            ),
            onSubmitted: (_) => _applyFilters(),
            onChanged: (_) => setState(() {}),
          ),
        ),
        _statusDropdown(),
        FilledButton.tonalIcon(
          onPressed: _applyFilters,
          icon: const Icon(Icons.filter_alt, size: 16),
          label: const Text('Apply'),
        ),
        if (_searchCtrl.text.isNotEmpty || _statusFilter != null || _strategyFilter != null)
          TextButton.icon(
            onPressed: _clear,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Clear'),
          ),
      ],
    );
  }

  Widget _statusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TradeStatus?>(
          value: _statusFilter,
          hint: const Text('All status'),
          dropdownColor: AppColors.surfaceHigh,
          style: const TextStyle(color: AppColors.textPrimary),
          items: const [
            DropdownMenuItem(value: null, child: Text('All status')),
            DropdownMenuItem(value: TradeStatus.open, child: Text('Open')),
            DropdownMenuItem(value: TradeStatus.closed, child: Text('Closed')),
            DropdownMenuItem(value: TradeStatus.cancelled, child: Text('Cancelled')),
          ],
          onChanged: (v) {
            setState(() => _statusFilter = v);
          },
        ),
      ),
    );
  }

  Widget _body(TradesProvider p, double pad) {
    if (p.loading && p.trades.isEmpty) return const LoadingView();
    if (p.error != null && p.trades.isEmpty) {
      return ErrorView(message: p.error!, onRetry: () => p.load(filters: p.filters));
    }
    if (p.trades.isEmpty) {
      return EmptyState(
        icon: Icons.candlestick_chart_outlined,
        title: 'No trades match those filters',
        subtitle: 'Try adjusting filters, or log a new trade.',
        action: FilledButton.icon(
          onPressed: () => context.go('/trades/new'),
          icon: const Icon(Icons.add),
          label: const Text('Log a trade'),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(pad, 0, pad, 80),
      itemCount: p.trades.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final trade = p.trades[i];
        return TradeCard(trade: trade, onTap: () => context.go('/trades/${trade.id}'));
      },
    );
  }
}
