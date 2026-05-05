import 'package:flutter/foundation.dart';

import '../models/trade.dart';
import '../services/api_client.dart';
import '../services/trade_service.dart';

class TradesProvider extends ChangeNotifier {
  final TradeService _service;
  TradesProvider(this._service);

  bool _loading = false;
  String? _error;
  List<Trade> _trades = [];
  int _total = 0;
  TradeListFilters _filters = const TradeListFilters();

  bool get loading => _loading;
  String? get error => _error;
  List<Trade> get trades => List.unmodifiable(_trades);
  int get total => _total;
  TradeListFilters get filters => _filters;

  Future<void> load({TradeListFilters? filters}) async {
    if (filters != null) _filters = filters;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _service.list(_filters);
      _trades = result.items;
      _total = result.total;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Trade?> create(TradeInput input) async {
    try {
      final trade = await _service.create(input);
      _trades = [trade, ..._trades];
      _total += 1;
      notifyListeners();
      return trade;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<Trade?> update(String id, TradeInput input) async {
    try {
      final updated = await _service.update(id, input);
      _replace(updated);
      return updated;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _service.delete(id);
      _trades = _trades.where((t) => t.id != id).toList();
      _total = (_total - 1).clamp(0, 1 << 30);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<Trade?> uploadScreenshot(
    String id, {
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    try {
      final updated = await _service.uploadScreenshot(
        tradeId: id,
        bytes: bytes,
        filename: filename,
        contentType: contentType,
      );
      _replace(updated);
      return updated;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }

  void _replace(Trade updated) {
    _trades = [
      for (final t in _trades) t.id == updated.id ? updated : t,
    ];
    notifyListeners();
  }
}
