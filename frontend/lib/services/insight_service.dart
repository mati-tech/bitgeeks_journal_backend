import '../models/insight.dart';
import 'api_client.dart';

class InsightService {
  final ApiClient client;
  InsightService(this.client);

  Future<InsightGenerateResult> generate({int lookback = 50}) async {
    final res = await client.post<Map<String, dynamic>>(
      '/api/insights/generate',
      query: {'lookback': lookback},
    );
    return InsightGenerateResult.fromJson(res.data!);
  }

  Future<List<Insight>> list({int limit = 50}) async {
    final res = await client.get<List<dynamic>>('/api/insights', query: {'limit': limit});
    return res.data!.map((e) => Insight.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Insight> get(String id) async {
    final res = await client.get<Map<String, dynamic>>('/api/insights/$id');
    return Insight.fromJson(res.data!);
  }

  Future<void> dismiss(String id) async {
    await client.delete('/api/insights/$id');
  }
}
