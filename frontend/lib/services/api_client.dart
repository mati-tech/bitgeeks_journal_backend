import 'package:dio/dio.dart';

import '../config/constants.dart';
import 'storage_service.dart';

/// Surfaces structured failures so providers/UI can show useful messages.
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic raw;

  ApiException({this.statusCode, required this.message, this.raw});

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

typedef UnauthorizedHandler = void Function();

class ApiClient {
  final Dio dio;
  UnauthorizedHandler? onUnauthorized;

  ApiClient({Dio? dio})
      : dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConstants.apiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              headers: {'Accept': 'application/json'},
            )) {
    this.dio.interceptors.add(InterceptorsWrapper(
          onRequest: (options, handler) async {
            final token = await StorageService.readToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            handler.next(options);
          },
          onError: (e, handler) {
            if (e.response?.statusCode == 401) {
              onUnauthorized?.call();
            }
            handler.next(e);
          },
        ));
  }

  Future<T> _wrap<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String message;
    if (data is Map && data['detail'] != null) {
      final detail = data['detail'];
      message = detail is String ? detail : detail.toString();
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      message = 'Could not reach the server. Check your connection.';
    } else {
      message = e.message ?? 'Unexpected error';
    }
    return ApiException(statusCode: status, message: message, raw: data);
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) =>
      _wrap(() => dio.get<T>(path, queryParameters: query));

  Future<Response<T>> post<T>(String path,
          {Object? body, Map<String, dynamic>? query, Options? options}) =>
      _wrap(() => dio.post<T>(path, data: body, queryParameters: query, options: options));

  Future<Response<T>> put<T>(String path, {Object? body}) =>
      _wrap(() => dio.put<T>(path, data: body));

  Future<Response<T>> delete<T>(String path) => _wrap(() => dio.delete<T>(path));
}
