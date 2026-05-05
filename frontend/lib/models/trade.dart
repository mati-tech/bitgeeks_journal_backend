enum TradeType { long, short }

extension TradeTypeX on TradeType {
  String get apiValue => this == TradeType.long ? 'LONG' : 'SHORT';
  String get label => this == TradeType.long ? 'Long' : 'Short';
  static TradeType fromApi(String s) =>
      s.toUpperCase() == 'SHORT' ? TradeType.short : TradeType.long;
}

enum TradeStatus { open, closed, cancelled }

extension TradeStatusX on TradeStatus {
  String get apiValue => name;
  String get label => switch (this) {
    TradeStatus.open => 'Open',
    TradeStatus.closed => 'Closed',
    TradeStatus.cancelled => 'Cancelled',
  };
  static TradeStatus fromApi(String s) {
    switch (s) {
      case 'closed':
        return TradeStatus.closed;
      case 'cancelled':
        return TradeStatus.cancelled;
      default:
        return TradeStatus.open;
    }
  }
}

double? _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

class Trade {
  final String id;
  final String userId;

  final String symbol;
  final TradeType tradeType;
  final double entryPrice;
  final double? exitPrice;
  final double positionSize;
  final int leverage;

  final DateTime entryTime;
  final DateTime? exitTime;

  final double? pnl;
  final double? pnlPercentage;
  final double fees;

  final String? strategy;
  final String? timeframe;
  final String? notes;
  final String? emotions;
  final String? screenshotUrl;

  final TradeStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Trade({
    required this.id,
    required this.userId,
    required this.symbol,
    required this.tradeType,
    required this.entryPrice,
    required this.exitPrice,
    required this.positionSize,
    required this.leverage,
    required this.entryTime,
    required this.exitTime,
    required this.pnl,
    required this.pnlPercentage,
    required this.fees,
    required this.strategy,
    required this.timeframe,
    required this.notes,
    required this.emotions,
    required this.screenshotUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isWinner => (pnl ?? 0) > 0;
  bool get isLoser => (pnl ?? 0) < 0;
  bool get isClosed => status == TradeStatus.closed;
  Duration? get duration =>
      exitTime == null ? null : exitTime!.difference(entryTime);

  List<String> get emotionList =>
      (emotions ?? '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  factory Trade.fromJson(Map<String, dynamic> json) => Trade(
    id: json['id'] as String? ?? '',
    userId: json['user_id'] as String? ?? '',
    symbol: json['symbol'] as String? ?? '',
    tradeType: json['trade_type'] != null
        ? TradeTypeX.fromApi(json['trade_type'] as String)
        : TradeType.long,
    // FIX: Removed force unwrap — now safe with defaults
    entryPrice: _toDouble(json['entry_price']) ?? 0.0,
    exitPrice: _toDouble(json['exit_price']),
    positionSize: _toDouble(json['position_size']) ?? 0.0,
    leverage: (json['leverage'] as num?)?.toInt() ?? 1,
    entryTime: json['entry_time'] != null
        ? DateTime.parse(json['entry_time'] as String)
        : DateTime.now(),
    exitTime: json['exit_time'] != null
        ? DateTime.parse(json['exit_time'] as String)
        : null,
    pnl: _toDouble(json['pnl']),
    pnlPercentage: _toDouble(json['pnl_percentage']),
    fees: _toDouble(json['fees']) ?? 0.0,
    strategy: json['strategy'] as String?,
    timeframe: json['timeframe'] as String?,
    notes: json['notes'] as String?,
    emotions: json['emotions'] as String?,
    screenshotUrl: json['screenshot_url'] as String?,
    status: json['status'] != null
        ? TradeStatusX.fromApi(json['status'] as String)
        : TradeStatus.open,
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : DateTime.now(),
    updatedAt: json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : DateTime.now(),
  );
}

class TradeListResult {
  final List<Trade> items;
  final int total;
  final int limit;
  final int offset;

  const TradeListResult({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory TradeListResult.fromJson(Map<String, dynamic> json) => TradeListResult(
    // FIX: Safe list handling
    items: (json['items'] as List<dynamic>?)
        ?.map((e) => Trade.fromJson(e as Map<String, dynamic>))
        .toList() ??
        [],
    total: (json['total'] as num?)?.toInt() ?? 0,
    limit: (json['limit'] as num?)?.toInt() ?? 0,
    offset: (json['offset'] as num?)?.toInt() ?? 0,
  );
}

/// Payload for create + update. Pass only the fields you want to send.
class TradeInput {
  final String? symbol;
  final TradeType? tradeType;
  final double? entryPrice;
  final double? exitPrice;
  final double? positionSize;
  final int? leverage;
  final DateTime? entryTime;
  final DateTime? exitTime;
  final double? fees;
  final String? strategy;
  final String? timeframe;
  final String? notes;
  final String? emotions;
  final TradeStatus? status;

  const TradeInput({
    this.symbol,
    this.tradeType,
    this.entryPrice,
    this.exitPrice,
    this.positionSize,
    this.leverage,
    this.entryTime,
    this.exitTime,
    this.fees,
    this.strategy,
    this.timeframe,
    this.notes,
    this.emotions,
    this.status,
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    if (symbol != null) m['symbol'] = symbol;
    if (tradeType != null) m['trade_type'] = tradeType!.apiValue;
    // FIX: Send numbers as numbers, not strings.
    // If your backend truly expects strings, revert these.
    if (entryPrice != null) m['entry_price'] = entryPrice;
    if (exitPrice != null) m['exit_price'] = exitPrice;
    if (positionSize != null) m['position_size'] = positionSize;
    if (leverage != null) m['leverage'] = leverage;
    if (entryTime != null) m['entry_time'] = entryTime!.toUtc().toIso8601String();
    if (exitTime != null) m['exit_time'] = exitTime!.toUtc().toIso8601String();
    // FIX: Same for fees — send as number
    if (fees != null) m['fees'] = fees;
    if (strategy != null) m['strategy'] = strategy;
    if (timeframe != null) m['timeframe'] = timeframe;
    if (notes != null) m['notes'] = notes;
    if (emotions != null) m['emotions'] = emotions;
    if (status != null) m['status'] = status!.apiValue;
    return m;
  }
}