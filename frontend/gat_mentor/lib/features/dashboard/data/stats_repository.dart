import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../auth/data/auth_repository.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(ref.read(apiClientProvider));
});

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

class StatsRepository {
  final ApiClient _api;

  StatsRepository(this._api);

  /// Fetch the main dashboard summary.
  /// Returns a map with: totalQuestionsDone, totalCorrect, overallAccuracy,
  /// avgTime, streak, masterySummary, weakestConcepts.
  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await _api.get(ApiConstants.dashboard);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Fetch the full mastery map grouped by topic.
  /// Returns a list of {topic_name, concepts: [{name, mastery, accuracy}]}.
  Future<List<dynamic>> getMasteryMap() async {
    try {
      final response = await _api.get(ApiConstants.masteryMap);
      final data = response.data;
      // Backend wraps the list in {"topics": [...]}
      if (data is Map<String, dynamic> && data.containsKey('topics')) {
        return data['topics'] as List<dynamic>;
      }
      return data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Fetch accuracy/time trends over a number of days.
  /// Returns a list of {date, accuracy, avgTime, questionsDone}.
  Future<List<dynamic>> getTrends(int days) async {
    try {
      final response = await _api.get(
        ApiConstants.trends,
        queryParams: {'days': days},
      );
      final data = response.data;
      // Backend wraps the list in {"daily_trends": [...], "period": "..."}
      if (data is Map<String, dynamic> && data.containsKey('daily_trends')) {
        return data['daily_trends'] as List<dynamic>;
      }
      return data as List<dynamic>;
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
