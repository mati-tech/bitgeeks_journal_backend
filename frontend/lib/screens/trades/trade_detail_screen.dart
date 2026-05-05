import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/trade.dart';
import '../../providers/trades_provider.dart';
import '../../services/trade_service.dart';
import '../../utils/formatters.dart';
import '../../utils/responsive.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/pnl_text.dart';

class TradeDetailScreen extends StatefulWidget {
  final String tradeId;
  const TradeDetailScreen({super.key, required this.tradeId});

  @override
  State<TradeDetailScreen> createState() => _TradeDetailScreenState();
}

class _TradeDetailScreenState extends State<TradeDetailScreen> {
  bool _loading = false;
  bool _uploading = false;
  String? _error;
  Trade? _trade;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final p = context.read<TradesProvider>();
    Trade? cached;
    try {
      cached = p.trades.firstWhere((t) => t.id == widget.tradeId);
    } catch (_) {
      cached = null;
    }

    if (cached != null) {
      setState(() => _trade = cached);
      return;
    }

    setState(() => _loading = true);
    try {
      // Try the list endpoint as a fallback (cheap, no per-item endpoint exposed in TradeService).
      await p.load(filters: const TradeListFilters(limit: 200));
      Trade? found;
      try {
        found = p.trades.firstWhere((t) => t.id == widget.tradeId);
      } catch (_) {
        found = null;
      }
      setState(() {
        _trade = found;
        _error = found == null ? 'Trade not found' : null;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this trade?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.loss),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = await context.read<TradesProvider>().delete(widget.tradeId);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trade deleted')));
      context.go('/trades');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<TradesProvider>().error ?? 'Delete failed')),
      );
    }
  }

  Future<void> _uploadScreenshot() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1920);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final mime = picked.mimeType ?? _guessMime(picked.name);
    setState(() => _uploading = true);
    final updated = await context.read<TradesProvider>().uploadScreenshot(
          widget.tradeId,
          bytes: bytes,
          filename: picked.name,
          contentType: mime,
        );
    if (!mounted) return;
    setState(() {
      _uploading = false;
      if (updated != null) _trade = updated;
    });
    if (updated == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<TradesProvider>().error ?? 'Upload failed')),
      );
    }
  }

  String _guessMime(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: LoadingView());
    }
    if (_trade == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.canPop() ? context.pop() : context.go('/trades'),
          ),
        ),
        body: ErrorView(message: _error ?? 'Trade not found', onRetry: _load),
      );
    }
    final t = _trade!;
    final pad = responsive(context, mobile: 16.0, tablet: 32.0, desktop: 48.0);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/trades'),
        ),
        title: Row(
          children: [
            Text(t.symbol),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: t.tradeType == TradeType.long ? AppColors.profitSoft : AppColors.lossSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                t.tradeType.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: t.tradeType == TradeType.long ? AppColors.profit : AppColors.loss,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.go('/trades/${t.id}/edit'),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline, color: AppColors.loss),
            onPressed: _delete,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: 24),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _pnlHero(t),
                const SizedBox(height: 24),
                _detailsGrid(t),
                if (t.notes != null && t.notes!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Notes',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.textMuted, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(t.notes!, style: const TextStyle(height: 1.5)),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _screenshotSection(t),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pnlHero(Trade t) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PROFIT & LOSS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            PnlText(
              value: t.pnl,
              percentage: t.pnlPercentage,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _miniStat('Entry', formatMoney(t.entryPrice)),
                _miniStat('Exit', t.exitPrice == null ? '—' : formatMoney(t.exitPrice)),
                _miniStat('Size', t.positionSize.toString()),
                _miniStat('Leverage', '${t.leverage}x'),
                _miniStat('Fees', formatMoney(t.fees)),
                if (t.duration != null) _miniStat('Duration', formatDuration(t.duration)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10, letterSpacing: 0.8)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _detailsGrid(Trade t) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _row('Status', t.status.label),
            _row('Strategy', t.strategy ?? '—'),
            _row('Timeframe', t.timeframe ?? '—'),
            _row('Entry time', formatDateTime(t.entryTime)),
            _row('Exit time', formatDateTime(t.exitTime)),
            _row('Emotions', t.emotionList.isEmpty ? '—' : t.emotionList.join(', ')),
            _row('Created', formatDateTime(t.createdAt), isLast: true),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(label,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
              Expanded(
                child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ),
            ],
          ),
          if (!isLast) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  Widget _screenshotSection(Trade t) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Screenshot',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textMuted, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                ),
                if (!kIsWeb)
                  TextButton.icon(
                    onPressed: _uploading ? null : _uploadScreenshot,
                    icon: _uploading
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.upload, size: 16),
                    label: Text(t.screenshotUrl == null ? 'Upload' : 'Replace'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (t.screenshotUrl == null)
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.image_outlined, size: 32, color: AppColors.textMuted),
                      const SizedBox(height: 6),
                      Text(
                        kIsWeb
                            ? 'Screenshot upload not supported on web in this build.'
                            : 'No screenshot uploaded',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  '${AppConstants.apiBaseUrl}${t.screenshotUrl}',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: AppColors.surfaceHigh,
                    child: const Center(
                      child: Text('Could not load image', style: TextStyle(color: AppColors.textMuted)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
