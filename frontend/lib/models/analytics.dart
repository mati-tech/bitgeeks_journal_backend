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
        totalTrades: json['total_trades'] as int,
        openTrades: json['open_trades'] as int,
        closedTrades: json['closed_trades'] as int,
        winningTrades: json['winning_trades'] as int,
        losingTrades: json['losing_trades'] as int,
        winRate: (json['win_rate'] as num).toDouble(),
        totalPnl: _toD(json['total_pnl']) ?? 0,
        totalFees: _toD(json['total_fees']) ?? 0,
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
        period: json['period'] as String,
        trades: json['trades'] as int,
        pnl: _toD(json['pnl']) ?? 0,
        cumulativePnl: _toD(json['cumulative_pnl']) ?? 0,
      );
}

class PerformanceSeries {
  final String interval;
  final List<PerformancePoint> points;

  const PerformanceSeries({required this.interval, required this.points});

  factory PerformanceSeries.fromJson(Map<String, dynamic> json) => PerformanceSeries(
        interval: json['interval'] as String,
        points: (json['points'] as List)
            .map((e) => PerformancePoint.fromJson(e as Map<String, dynamic>))
            .toList(),
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
        key: json['key'] as String,
        trades: json['trades'] as int,
        pnl: _toD(json['pnl']) ?? 0,
        winRate: (json['win_rate'] as num).toDouble(),
      );
}

class GroupedResponse {
  final String groupBy;
  final List<GroupedRow> items;

  const GroupedResponse({required this.groupBy, required this.items});

  factory GroupedResponse.fromJson(Map<String, dynamic> json) => GroupedResponse(
        groupBy: json['group_by'] as String,
        items: (json['items'] as List)
            .map((e) => GroupedRow.fromJson(e as Map<String, dynamic>))
            .toList(),
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
        emotion: json['emotion'] as String,
        trades: json['trades'] as int,
        pnl: _toD(json['pnl']) ?? 0,
        winRate: (json['win_rate'] as num).toDouble(),
      );
}

class EmotionalAnalysis {
  final List<EmotionRow> items;
  const EmotionalAnalysis({required this.items});

  factory EmotionalAnalysis.fromJson(Map<String, dynamic> json) => EmotionalAnalysis(
        items: (json['items'] as List)
            .map((e) => EmotionRow.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
