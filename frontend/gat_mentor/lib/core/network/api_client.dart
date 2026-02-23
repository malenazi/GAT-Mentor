import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

/// Broadcast stream that fires when the server returns 401.
/// The app shell listens to this and shows a "session expired" dialog.
final sessionExpiredController = StreamController<void>.broadcast();

class ApiClient {
  late final Dio dio;

  /// On web, build an absolute URL from the current page origin so Dio
  /// works both on the Flutter dev-server (proxied or same-origin) and in
  /// production where the backend serves the SPA.
  static String _resolveBaseUrl() {
    if (!kIsWeb) return ApiConstants.baseUrl;
    try {
      final uri = Uri.base;
      final origin =
          '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
      return '$origin/api/v1';
    } catch (_) {
      return ApiConstants.webBaseUrl;
    }
  }

  ApiClient() {
    final baseUrl = _resolveBaseUrl();

    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(AuthInterceptor());
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) =>
      dio.get(path, queryParameters: queryParams);

  Future<Response> post(String path, {dynamic data}) =>
      dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      dio.put(path, data: data);

  Future<Response> delete(String path) => dio.delete(path);
}

/// Uses [QueuedInterceptor] so that the async token read is properly awaited
/// before the request is sent.
class AuthInterceptor extends QueuedInterceptor {
  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final token = await SecureStorage.getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // If storage read fails, continue without token.
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      SecureStorage.deleteToken();
      // Notify listeners so the UI can show "session expired" dialog.
      sessionExpiredController.add(null);
    }
    handler.next(err);
  }
}
