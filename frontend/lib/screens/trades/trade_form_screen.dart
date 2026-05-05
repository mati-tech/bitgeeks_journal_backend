import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/trade.dart';
import '../../providers/trades_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/responsive.dart';
import '../../utils/validators.dart';
import '../../widgets/loading_view.dart';

const _strategies = [
  'Breakout',
  'Mean Reversion',
  'Trend Following',
  'Scalp',
  'Swing',
  'News',
  'Other',
];

const _timeframes = ['1m', '5m', '15m', '30m', '1h', '4h', '1D', '1W'];

const _emotionTags = [
  'confident',
  'fearful',
  'fomo',
  'greedy',
  'disciplined',
  'revenge',
  'patient',
  'uncertain',
];

class TradeFormScreen extends StatefulWidget {
  final String? tradeId;
  const TradeFormScreen({super.key, this.tradeId});

  @override
  State<TradeFormScreen> createState() => _TradeFormScreenState();
}

class _TradeFormScreenState extends State<TradeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _symbol = TextEditingController();
  final _entryPrice = TextEditingController();
  final _exitPrice = TextEditingController();
  final _positionSize = TextEditingController();
  final _fees = TextEditingController(text: '0');
  final _notes = TextEditingController();

  TradeType _tradeType = TradeType.long;
  int _leverage = 1;
  String? _strategy;
  String? _timeframe;
  TradeStatus _status = TradeStatus.open;
  DateTime _entryTime = DateTime.now();
  DateTime? _exitTime;
  final Set<String> _emotions = {};

  bool _loading = false;
  bool _saving = false;

  bool get _isEdit => widget.tradeId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _hydrate();
    }
  }

  Future<void> _hydrate() async {
    setState(() => _loading = true);
    try {
      final list = context.read<TradesProvider>().trades;
      // FIX: Use firstWhere with orElse to avoid try/catch for control flow
      Trade? t = list.cast<Trade?>().firstWhere(
            (tr) => tr?.id == widget.tradeId,
        orElse: () => null,
      );

      // Fall back to list reload if trade not in cache.
      if (t == null) {
        await context.read<TradesProvider>().load();
        t = context.read<TradesProvider>().trades.cast<Trade?>().firstWhere(
              (tr) => tr?.id == widget.tradeId,
          orElse: () => null,
        );
      }
      if (t != null) {
        _symbol.text = t.symbol;
        _tradeType = t.tradeType;
        _entryPrice.text = t.entryPrice.toString();
        _exitPrice.text = t.exitPrice?.toString() ?? '';
        _positionSize.text = t.positionSize.toString();
        _fees.text = t.fees.toString();
        _leverage = t.leverage;
        _strategy = t.strategy;
        _timeframe = t.timeframe;
        _status = t.status;
        _entryTime = t.entryTime;
        _exitTime = t.exitTime;
        _emotions.addAll(t.emotionList);
        _notes.text = t.notes ?? '';
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _symbol.dispose();
    _entryPrice.dispose();
    _exitPrice.dispose();
    _positionSize.dispose();
    _fees.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickEntryTime() async {
    final picked = await _pickDateTime(_entryTime);
    if (picked != null) setState(() => _entryTime = picked);
  }

  Future<void> _pickExitTime() async {
    final picked = await _pickDateTime(_exitTime ?? DateTime.now());
    if (picked != null) setState(() => _exitTime = picked);
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // FIX: Added missing parseNumOrNull helper
  double? parseNumOrNull(String s) {
    if (s.trim().isEmpty) return null;
    return double.tryParse(s.trim());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_status == TradeStatus.closed && (_exitPrice.text.trim().isEmpty || _exitTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Closed trades need an exit price and exit time.')),
      );
      return;
    }

    setState(() => _saving = true);
    final input = TradeInput(
      symbol: _symbol.text.trim().toUpperCase(),
      tradeType: _tradeType,
      entryPrice: parseNumOrNull(_entryPrice.text),
      exitPrice: parseNumOrNull(_exitPrice.text),
      positionSize: parseNumOrNull(_positionSize.text),
      leverage: _leverage,
      entryTime: _entryTime,
      exitTime: _exitTime,
      fees: parseNumOrNull(_fees.text) ?? 0,
      strategy: _strategy,
      timeframe: _timeframe,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      emotions: _emotions.isEmpty ? null : _emotions.join(', '),
      status: _status,
    );

    final provider = context.read<TradesProvider>();
    final result = _isEdit
        ? await provider.update(widget.tradeId!, input)
        : await provider.create(input);

    if (!mounted) return;
    setState(() => _saving = false);

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Trade updated' : 'Trade saved')),
      );
      context.go('/trades/${result.id}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to save')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: LoadingView());
    }
    final pad = responsive(context, mobile: 16.0, tablet: 32.0, desktop: 48.0);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/trades'),
        ),
        title: Text(_isEdit ? 'Edit trade' : 'Log a new trade'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: pad, vertical: 24),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _section('Trade'),
                  TextFormField(
                    controller: _symbol,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Symbol', hintText: 'e.g. BTC/USDT'),
                    validator: (v) => requiredField(v, 'Symbol'),
                  ),
                  const SizedBox(height: 14),
                  _typeAndLeverage(),
                  const SizedBox(height: 14),
                  _row([
                    TextFormField(
                      controller: _entryPrice,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Entry price'),
                      validator: (v) => validatePositiveNumber(v, label: 'Entry price'),
                    ),
                    TextFormField(
                      controller: _positionSize,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Position size'),
                      validator: (v) => validatePositiveNumber(v, label: 'Position size'),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  _row([
                    TextFormField(
                      controller: _exitPrice,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Exit price',
                        helperText: _status == TradeStatus.closed ? 'Required for closed trades' : 'Leave empty if still open',
                      ),
                      validator: (v) => validatePositiveNumber(v, allowEmpty: true, label: 'Exit price'),
                    ),
                    TextFormField(
                      controller: _fees,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Fees', hintText: '0'),
                      validator: (v) => validateNonNegativeNumber(v, label: 'Fees'),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _section('Timing'),
                  _row([
                    _dateTimeField(
                      label: 'Entry time',
                      value: _entryTime,
                      onTap: _pickEntryTime,
                    ),
                    _dateTimeField(
                      label: 'Exit time',
                      value: _exitTime,
                      onTap: _pickExitTime,
                      onClear: _exitTime == null ? null : () => setState(() => _exitTime = null),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  _statusSegmented(),
                  const SizedBox(height: 24),
                  _section('Context'),
                  _row([
                    // FIX: Changed 'initialValue' to 'value'
                    DropdownButtonFormField<String?>(
                      value: _strategy,
                      decoration: const InputDecoration(labelText: 'Strategy'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('—')),
                        for (final s in _strategies)
                          DropdownMenuItem(value: s, child: Text(s)),
                      ],
                      onChanged: (v) => setState(() => _strategy = v),
                    ),
                    // FIX: Changed 'initialValue' to 'value'
                    DropdownButtonFormField<String?>(
                      value: _timeframe,
                      decoration: const InputDecoration(labelText: 'Timeframe'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('—')),
                        for (final t in _timeframes)
                          DropdownMenuItem(value: t, child: Text(t)),
                      ],
                      onChanged: (v) => setState(() => _timeframe = v),
                    ),
                  ]),
                  const SizedBox(height: 18),
                  Text('Emotions',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final emo in _emotionTags)
                        FilterChip(
                          label: Text(emo),
                          selected: _emotions.contains(emo),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _emotions.add(emo);
                              } else {
                                _emotions.remove(emo);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _notes,
                    minLines: 3,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      alignLabelWithHint: true,
                      hintText: 'What was your thesis? What happened?',
                    ),
                  ),
                  const SizedBox(height: 32),
                  _saveButtons(),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text(
      t.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.textMuted,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _row(List<Widget> children) {
    if (context.isMobile) {
      return Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const SizedBox(height: 14),
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i < children.length - 1) const SizedBox(width: 14),
        ],
      ],
    );
  }

  Widget _typeAndLeverage() {
    return _row([
      _segmentControl<TradeType>(
        label: 'Direction',
        value: _tradeType,
        items: const {
          TradeType.long: 'Long',
          TradeType.short: 'Short',
        },
        onChanged: (v) => setState(() => _tradeType = v),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Leverage: ${_leverage}x',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textSecondary)),
          Slider(
            min: 1,
            max: 125,
            divisions: 124,
            value: _leverage.toDouble(),
            label: '${_leverage}x',
            onChanged: (v) => setState(() => _leverage = v.round()),
          ),
        ],
      ),
    ]);
  }

  Widget _statusSegmented() {
    return _segmentControl<TradeStatus>(
      label: 'Status',
      value: _status,
      items: const {
        TradeStatus.open: 'Open',
        TradeStatus.closed: 'Closed',
        TradeStatus.cancelled: 'Cancelled',
      },
      onChanged: (v) => setState(() => _status = v),
    );
  }

  Widget _segmentControl<T>({
    required String label,
    required T value,
    required Map<T, String> items,
    required ValueChanged<T> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<T>(
            showSelectedIcon: false,
            segments: [
              for (final entry in items.entries)
                ButtonSegment(value: entry.key, label: Text(entry.value)),
            ],
            selected: {value},
            onSelectionChanged: (s) => onChanged(s.first),
          ),
        ),
      ],
    );
  }

  Widget _dateTimeField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: onClear != null
              ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onClear)
              : const Icon(Icons.event_outlined, size: 18),
        ),
        child: Text(
          value == null ? '—' : formatDateTime(value),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  Widget _saveButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _saving ? null : () => context.pop(),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save),
            label: Text(_isEdit ? 'Save changes' : 'Log trade'),
          ),
        ),
      ],
    );
  }
}