// Moved _toD to a shared location or kept here.
// If trade.dart is in the same library, remove the duplicate from trade.dart
// and import this one. Assuming separate libraries, both keep their own.

double? _toD(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

class AnalyticsSummary {
  final int totalTrades;
  final int openTrades;
  final int closedTrades;
  final int winningTrades;
  final int losingTrades;
  final double winRate;
  final double totalPnl;
  final double totalFees;
  final double? avgPnl;
  final double? avgWinner;
  final double? avgLoser;
  final double? bestTrade;
  final double? worstTrade;

  const AnalyticsSummary({
    required this.totalTrades,
    required this.openTrades,
    required this.closedTrades,
    required this.winningTrades,
    required this.losingTrades,
    required this.winRate,
    required this.totalPnl,
    required this.totalFees,
    required this.avgPnl,
    required this.avgWinner,
    required this.avgLoser,
    required this.bestTrade,
    required this.worstTrade,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) => AnalyticsSummary(
    totalTrades: (json['total_trades'] as num?)?.toInt() ?? 0,
    openTrades: (json['open_trades'] as num?)?.toInt() ?? 0,
    closedTrades: (json['closed_trades'] as num?)?.toInt() ?? 0,
    winningTrades: (json['winning_trades'] as num?)?.toInt() ?? 0,
    losingTrades: (json['losing_trades'] as num?)?.toInt() ?? 0,
    // FIX: Safe cast — win_rate could be int or double from JSON
    winRate: (json['win_rate'] as num?)?.toDouble() ?? 0.0,
    totalPnl: _toD(json['total_pnl']) ?? 0.0,
    totalFees: _toD(json['total_fees']) ?? 0.0,
    avgPnl: _toD(json['avg_pnl']),
    avgWinner: _toD(json['avg_winner']),
    avgLoser: _toD(json['avg_loser']),
    bestTrade: _toD(json['best_trade']),
    worstTrade: _toD(json['worst_trade']),
  );
}

class PerformancePoint {
  final String period;
  final int trades;
  final double pnl;
  final double cumulativePnl;

  const PerformancePoint({
    required this.period,
    required this.trades,
    required this.pnl,
    required this.cumulativePnl,
  });

  factory PerformancePoint.fromJson(Map<String, dynamic> json) => PerformancePoint(
    period: json['period'] as String? ?? '',
    // FIX: Safe int parsing
    trades: (json['trades'] as num?)?.toInt() ?? 0,
    pnl: _toD(json['pnl']) ?? 0.0,
    cumulativePnl: _toD(json['cumulative_pnl']) ?? 0.0,
  );
}

class PerformanceSeries {
  final String interval;
  final List<PerformancePoint> points;

  const PerformanceSeries({required this.interval, required this.points});

  factory PerformanceSeries.fromJson(Map<String, dynamic> json) => PerformanceSeries(
    interval: json['interval'] as String? ?? '',
    // FIX: Safe list handling with fallback to empty list
    points: (json['points'] as List<dynamic>?)
        ?.map((e) => PerformancePoint.fromJson(e as Map<String, dynamic>))
        .toList() ??
        [],
  );
}

class GroupedRow {
  final String key;
  final int trades;
  final double pnl;
  final double winRate;

  const GroupedRow({
    required this.key,
    required this.trades,
    required this.pnl,
    required this.winRate,
  });

  factory GroupedRow.fromJson(Map<String, dynamic> json) => GroupedRow(
    key: json['key'] as String? ?? '',
    // FIX: Safe int parsing
    trades: (json['trades'] as num?)?.toInt() ?? 0,
    pnl: _toD(json['pnl']) ?? 0.0,
    // FIX: Safe double parsing to prevent crash on null
    winRate: (json['win_rate'] as num?)?.toDouble() ?? 0.0,
  );
}

class GroupedResponse {
  final String groupBy;
  final List<GroupedRow> items;

  const GroupedResponse({required this.groupBy, required this.items});

  factory GroupedResponse.fromJson(Map<String, dynamic> json) => GroupedResponse(
    groupBy: json['group_by'] as String? ?? '',
    // FIX: Safe list handling
    items: (json['items'] as List<dynamic>?)
        ?.map((e) => GroupedRow.fromJson(e as Map<String, dynamic>))
        .toList() ??
        [],
  );
}

class EmotionRow {
  final String emotion;
  final int trades;
  final double pnl;
  final double winRate;

  const EmotionRow({
    required this.emotion,
    required this.trades,
    required this.pnl,
    required this.winRate,
  });

  factory EmotionRow.fromJson(Map<String, dynamic> json) => EmotionRow(
    emotion: json['emotion'] as String? ?? '',
    // FIX: Safe int parsing
    trades: (json['trades'] as num?)?.toInt() ?? 0,
    pnl: _toD(json['pnl']) ?? 0.0,
    // FIX: Safe double parsing to prevent crash on null
    winRate: (json['win_rate'] as num?)?.toDouble() ?? 0.0,
  );
}

class EmotionalAnalysis {
  final List<EmotionRow> items;
  const EmotionalAnalysis({required this.items});

  factory EmotionalAnalysis.fromJson(Map<String, dynamic> json) => EmotionalAnalysis(
    // FIX: Safe list handling
    items: (json['items'] as List<dynamic>?)
        ?.map((e) => EmotionRow.fromJson(e as Map<String, dynamic>))
        .toList() ??
        [],
  );
}