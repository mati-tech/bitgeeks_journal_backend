import '../models/analytics.dart';
import 'api_client.dart';

class AnalyticsService {
  final ApiClient client;
  AnalyticsService(this.client);

  Future<AnalyticsSummary> summary() async {
    final res = await client.get<Map<String, dynamic>>('/api/analytics/summary');
    return AnalyticsSummary.fromJson(res.data!);
  }

  Future<PerformanceSeries> performance({
    String interval = 'day',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final res = await client.get<Map<String, dynamic>>(
      '/api/analytics/performance',
      query: {
        'interval': interval,
        if (startDate != null) 'start_date': startDate.toUtc().toIso8601String(),
        if (endDate != null) 'end_date': endDate.toUtc().toIso8601String(),
      },
    );
    return PerformanceSeries.fromJson(res.data!);
  }

  Future<GroupedResponse> byStrategy() async {
    final res = await client.get<Map<String, dynamic>>('/api/analytics/by-strategy');
    return GroupedResponse.fromJson(res.data!);
  }

  Future<GroupedResponse> bySymbol() async {
    final res = await client.get<Map<String, dynamic>>('/api/analytics/by-symbol');
    return GroupedResponse.fromJson(res.data!);
  }

  Future<EmotionalAnalysis> emotional() async {
    final res = await client.get<Map<String, dynamic>>('/api/analytics/emotional-analysis');
    return EmotionalAnalysis.fromJson(res.data!);
  }
}
