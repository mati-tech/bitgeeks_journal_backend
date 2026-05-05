import 'package:flutter/foundation.dart';

import '../models/insight.dart';
import '../services/api_client.dart';
import '../services/insight_service.dart';

class InsightsProvider extends ChangeNotifier {
  final InsightService _service;
  InsightsProvider(this._service);

  bool _loading = false;
  bool _generating = false;
  String? _error;
  List<Insight> _items = [];

  bool get loading => _loading;
  bool get generating => _generating;
  String? get error => _error;
  List<Insight> get items => List.unmodifiable(_items);

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _service.list();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<int?> generate({int lookback = 50}) async {
    _generating = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _service.generate(lookback: lookback);
      _items = [...result.items, ..._items];
      return result.generated;
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } finally {
      _generating = false;
      notifyListeners();
    }
  }

  Future<bool> dismiss(String id) async {
    try {
      await _service.dismiss(id);
      _items = _items.where((i) => i.id != id).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }
}
