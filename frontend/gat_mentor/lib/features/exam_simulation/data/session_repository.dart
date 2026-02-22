import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../auth/data/auth_repository.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(ref.read(apiClientProvider));
});

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

class SessionRepository {
  final ApiClient _api;

  SessionRepository(this._api);

  /// Start a new exam simulation session.
  /// Returns {id, questions} where questions is a list of question objects.
  Future<Map<String, dynamic>> startSession({
    required String type,
    required int questionCount,
    int? topicId,
    String? difficulty,
  }) async {
    try {
      final data = <String, dynamic>{
        'type': type,
        'question_count': questionCount,
      };
      if (topicId != null) data['topic_id'] = topicId;
      if (difficulty != null) data['difficulty'] = difficulty;

      final response = await _api.post(
        ApiConstants.startSession,
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Submit all answers for a completed session.
  /// Returns the result map with score, breakdown, etc.
  Future<Map<String, dynamic>> submitSession(
    int sessionId,
    List<Map<String, dynamic>> answers,
  ) async {
    try {
      final response = await _api.post(
        ApiConstants.submitSession(sessionId),
        data: {'answers': answers},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get the history of past simulation sessions.
  Future<List<dynamic>> getSessionHistory() async {
    try {
      final response = await _api.get(ApiConstants.sessionHistory);
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get a single session by ID.
  Future<Map<String, dynamic>> getSession(int sessionId) async {
    try {
      final response = await _api.get(ApiConstants.getSession(sessionId));
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
