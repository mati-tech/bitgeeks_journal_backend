enum InsightType { pattern, psychological, strategy }

extension InsightTypeX on InsightType {
  String get apiValue => name;
  String get label => switch (this) {
        InsightType.pattern => 'Pattern',
        InsightType.psychological => 'Psychological',
        InsightType.strategy => 'Strategy',
      };
  static InsightType fromApi(String s) {
    switch (s) {
      case 'psychological':
        return InsightType.psychological;
      case 'strategy':
        return InsightType.strategy;
      default:
        return InsightType.pattern;
    }
  }
}

enum InsightSeverity { info, warning, critical }

extension InsightSeverityX on InsightSeverity {
  String get apiValue => name;
  String get label => switch (this) {
        InsightSeverity.info => 'Info',
        InsightSeverity.warning => 'Warning',
        InsightSeverity.critical => 'Critical',
      };
  static InsightSeverity fromApi(String? s) {
    switch (s) {
      case 'warning':
        return InsightSeverity.warning;
      case 'critical':
        return InsightSeverity.critical;
      default:
        return InsightSeverity.info;
    }
  }
}

class Insight {
  final String id;
  final String userId;
  final InsightType insightType;
  final String title;
  final String description;
  final InsightSeverity severity;
  final List<String> relatedTrades;
  final double? confidenceScore;
  final DateTime createdAt;

  const Insight({
    required this.id,
    required this.userId,
    required this.insightType,
    required this.title,
    required this.description,
    required this.severity,
    required this.relatedTrades,
    required this.confidenceScore,
    required this.createdAt,
  });

  factory Insight.fromJson(Map<String, dynamic> json) => Insight(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        insightType: InsightTypeX.fromApi(json['insight_type'] as String),
        title: json['title'] as String,
        description: json['description'] as String,
        severity: InsightSeverityX.fromApi(json['severity'] as String?),
        relatedTrades: (json['related_trades'] as List?)?.cast<String>() ?? const [],
        confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class InsightGenerateResult {
  final int generated;
  final List<Insight> items;

  const InsightGenerateResult({required this.generated, required this.items});

  factory InsightGenerateResult.fromJson(Map<String, dynamic> json) =>
      InsightGenerateResult(
        generated: json['generated'] as int,
        items: (json['items'] as List)
            .map((e) => Insight.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
