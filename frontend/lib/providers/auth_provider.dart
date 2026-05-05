import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _service;
  final ApiClient _client;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _error;
  bool _busy = false;

  AuthProvider({required AuthService service, required ApiClient client})
      : _service = service,
        _client = client {
    _client.onUnauthorized = () {
      // FIX: Reset busy state if a 401 fires during an in-flight request,
      // otherwise UI stays stuck in loading state.
      _busy = false;
      _status = AuthStatus.unauthenticated;
      _user = null;
      StorageService.clearToken();
      notifyListeners();
    };
  }

  AuthStatus get status => _status;
  User? get user => _user;
  String? get error => _error;
  bool get busy => _busy;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> bootstrap() async {
    try {
      final token = await StorageService.readToken();
      if (token == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }
      try {
        _user = await _service.me();
        _status = AuthStatus.authenticated;
      } on ApiException {
        await StorageService.clearToken();
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      // FIX: Catch any unexpected error (timeout, format, storage) so the
      // provider doesn't stay stuck in AuthStatus.unknown forever.
      _status = AuthStatus.unauthenticated;
      _error = 'Failed to restore session';
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final session = await _service.login(email: email, password: password);
      await StorageService.saveToken(session.accessToken);
      _user = session.user;
      _status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final session = await _service.register(
        email: email,
        password: password,
        fullName: fullName,
      );
      await StorageService.saveToken(session.accessToken);
      _user = session.user;
      _status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await StorageService.clearToken();
    } catch (_) {
      // FIX: Don't crash if storage fails — still clear local state
    }
    _user = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    notifyListeners();
  }
}