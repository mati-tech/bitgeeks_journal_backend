import 'package:dio/dio.dart';

import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient client;
  AuthService(this.client);

  Future<AuthSession> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final res = await client.post<Map<String, dynamic>>(
      '/api/auth/register',
      body: {
        'email': email,
        'password': password,
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
      },
    );
    return AuthSession.fromJson(res.data!);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    // OAuth2 password flow expects application/x-www-form-urlencoded.
    final res = await client.post<Map<String, dynamic>>(
      '/api/auth/login',
      body: {'username': email, 'password': password},
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    return AuthSession.fromJson(res.data!);
  }

  Future<User> me() async {
    final res = await client.get<Map<String, dynamic>>('/api/auth/me');
    return User.fromJson(res.data!);
  }
}
