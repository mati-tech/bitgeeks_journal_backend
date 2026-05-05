import 'package:flutter/foundation.dart';

import '../models/analytics.dart';
import '../services/analytics_service.dart';
import '../services/api_client.dart';

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsService _service;
  AnalyticsProvider(this._service);

  bool _loading = false;
  String? _error;

  AnalyticsSummary? _summary;
  PerformanceSeries? _performance;
  GroupedResponse? _byStrategy;
  GroupedResponse? _bySymbol;
  EmotionalAnalysis? _emotional;

  String _interval = 'day';

  bool get loading => _loading;
  String? get error => _error;
  AnalyticsSummary? get summary => _summary;
  PerformanceSeries? get performance => _performance;
  GroupedResponse? get byStrategy => _byStrategy;
  GroupedResponse? get bySymbol => _bySymbol;
  EmotionalAnalysis? get emotional => _emotional;
  String get interval => _interval;

  Future<void> loadSummary() async {
    try {
      _summary = await _service.summary();
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  Future<void> loadAll({String? interval}) async {
    if (interval != null) _interval = interval;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.summary(),
        _service.performance(interval: _interval),
        _service.byStrategy(),
        _service.bySymbol(),
        _service.emotional(),
      ]);
      _summary = results[0] as AnalyticsSummary;
      _performance = results[1] as PerformanceSeries;
      _byStrategy = results[2] as GroupedResponse;
      _bySymbol = results[3] as GroupedResponse;
      _emotional = results[4] as EmotionalAnalysis;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setInterval(String interval) async {
    if (interval == _interval) return;
    _interval = interval;
    notifyListeners();
    try {
      _performance = await _service.performance(interval: _interval);
    } on ApiException catch (e) {
      _error = e.message;
    }
    notifyListeners();
  }
}
