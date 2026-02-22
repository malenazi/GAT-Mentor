import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../auth/data/auth_repository.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.read(apiClientProvider));
});

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

class ProfileRepository {
  final ApiClient _api;

  ProfileRepository(this._api);

  /// Update the user's profile (name, etc.).
  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> data) async {
    try {
      final response = await _api.put(
        ApiConstants.onboardingProfile,
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Update study plan settings (exam date, daily minutes, target score).
  Future<Map<String, dynamic>> updatePlanSettings({
    String? examDate,
    int? dailyMinutes,
    int? targetScore,
    String? level,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (examDate != null) data['exam_date'] = examDate;
      if (dailyMinutes != null) data['daily_minutes'] = dailyMinutes;
      if (targetScore != null) data['target_score'] = targetScore;
      if (level != null) data['level'] = level;

      final response = await _api.put(
        ApiConstants.planSettings,
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get the current streak info.
  Future<Map<String, dynamic>> getCurrentStreak() async {
    try {
      final response = await _api.get(ApiConstants.currentStreak);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get the dashboard stats (reusing for profile stats).
  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await _api.get(ApiConstants.dashboard);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Exception _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic> && data.containsKey('detail')) {
        return Exception(data['detail']);
      }
      return Exception('Server error. Please try again later.');
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
