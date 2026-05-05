import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/trade.dart';
import 'api_client.dart';

class TradeListFilters {
  final String? symbol;
  final String? strategy;
  final TradeStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;
  final int offset;

  const TradeListFilters({
    this.symbol,
    this.strategy,
    this.status,
    this.startDate,
    this.endDate,
    this.limit = 50,
    this.offset = 0,
  });

  Map<String, dynamic> toQuery() {
    final q = <String, dynamic>{'limit': limit, 'offset': offset};
    if (symbol != null && symbol!.isNotEmpty) q['symbol'] = symbol;
    if (strategy != null && strategy!.isNotEmpty) q['strategy'] = strategy;
    if (status != null) q['status'] = status!.apiValue;
    if (startDate != null) q['start_date'] = startDate!.toUtc().toIso8601String();
    if (endDate != null) q['end_date'] = endDate!.toUtc().toIso8601String();
    return q;
  }
}

class TradeService {
  final ApiClient client;
  TradeService(this.client);

  Future<TradeListResult> list([TradeListFilters? filters]) async {
    final res = await client.get<Map<String, dynamic>>(
      '/api/trades',
      query: (filters ?? const TradeListFilters()).toQuery(),
    );
    return TradeListResult.fromJson(res.data!);
  }

  Future<Trade> get(String id) async {
    final res = await client.get<Map<String, dynamic>>('/api/trades/$id');
    return Trade.fromJson(res.data!);
  }

  Future<Trade> create(TradeInput input) async {
    final res = await client.post<Map<String, dynamic>>('/api/trades', body: input.toJson());
    return Trade.fromJson(res.data!);
  }

  Future<Trade> update(String id, TradeInput input) async {
    final res = await client.put<Map<String, dynamic>>('/api/trades/$id', body: input.toJson());
    return Trade.fromJson(res.data!);
  }

  Future<void> delete(String id) async {
    await client.delete('/api/trades/$id');
  }

  Future<Trade> uploadScreenshot({
    required String tradeId,
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: DioMediaType.parse(contentType),
      ),
    });
    final res = await client.post<Map<String, dynamic>>(
      '/api/trades/$tradeId/screenshot',
      body: form,
    );
    return Trade.fromJson(res.data!);
  }
}
