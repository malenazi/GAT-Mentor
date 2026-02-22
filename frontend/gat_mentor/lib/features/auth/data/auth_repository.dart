import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'models/user_model.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(apiClientProvider));
});

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

class AuthRepository {
  final ApiClient _api;

  AuthRepository(this._api);

  /// Authenticate with email and password.
  /// Returns the access token on success.
  Future<String> login(String email, String password) async {
    try {
      final response = await _api.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      return response.data['access_token'] as String;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Register a new account.
  /// Returns the access token on success.
  Future<String> register(
      String email, String password, String fullName) async {
    try {
      final response = await _api.post(
        ApiConstants.register,
        data: {
          'email': email,
          'password': password,
          'full_name': fullName,
        },
      );
      return response.data['access_token'] as String;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Fetch the currently authenticated user's profile.
  Future<UserModel> getMe() async {
    try {
      final response = await _api.get(ApiConstants.me);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Convert Dio errors into human-readable exception messages.
  Exception _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic> && data.containsKey('detail')) {
        return Exception(data['detail']);
      }
      switch (e.response!.statusCode) {
        case 400:
          return Exception('Invalid request. Please check your input.');
        case 401:
          return Exception('Invalid email or password.');
        case 409:
          return Exception('An account with this email already exists.');
        case 422:
          return Exception('Please check your input and try again.');
        default:
          return Exception('Server error. Please try again later.');
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception(
          'Connection timed out. Please check your internet connection.');
    }
    return Exception(
        'Unable to connect to the server. Please check your internet connection.');
  }
}
