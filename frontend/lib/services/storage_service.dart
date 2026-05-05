import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/constants.dart';

/// On native we use flutter_secure_storage; on web that backend is shared
/// preferences anyway, so we go directly to SharedPreferences which doesn't
/// require any platform-channel dance.
class StorageService {
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> saveToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenStorageKey, token);
    } else {
      await _secure.write(key: AppConstants.tokenStorageKey, value: token);
    }
  }

  static Future<String?> readToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.tokenStorageKey);
    }
    return _secure.read(key: AppConstants.tokenStorageKey);
  }

  static Future<void> clearToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.tokenStorageKey);
    } else {
      await _secure.delete(key: AppConstants.tokenStorageKey);
    }
  }
}
