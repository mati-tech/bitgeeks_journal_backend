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
    _error = null; // FIX: Clear previous error
    try {
      _summary = await _service.summary();
    } on ApiException catch (e) {
      _error = e.message;
    }
    notifyListeners(); // FIX: Single notify after all state changes
  }

  Future<void> loadAll({String? interval}) async {
    if (interval != null) _interval = interval;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      // FIX: Use typed futures and await individually to avoid unsafe casts
      final summary = await _service.summary();
      final performance = await _service.performance(interval: _interval);
      final byStrategy = await _service.byStrategy();
      final bySymbol = await _service.bySymbol();
      final emotional = await _service.emotional();

      _summary = summary;
      _performance = performance;
      _byStrategy = byStrategy;
      _bySymbol = bySymbol;
      _emotional = emotional;
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
    _error = null; // FIX: Clear previous error
    notifyListeners(); // FIX: Only one notify for interval change
    try {
      _performance = await _service.performance(interval: _interval);
    } on ApiException catch (e) {
      _error = e.message;
    }
    notifyListeners(); // FIX: Only one more notify after result
  }
}