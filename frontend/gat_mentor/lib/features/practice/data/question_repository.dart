import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../auth/data/auth_repository.dart';
import 'models/attempt_model.dart';
import 'models/question_model.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepository(ref.read(apiClientProvider));
});

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

class QuestionRepository {
  final ApiClient _api;

  QuestionRepository(this._api);

  /// Fetch the next adaptive question for the student.
  ///
  /// All parameters are optional -- the backend picks the best question
  /// using its scheduling algorithm when no filters are provided.
  Future<QuestionModel> getNextQuestion({
    int? topicId,
    int? conceptId,
    int? difficulty,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (topicId != null) queryParams['topic_id'] = topicId;
      if (conceptId != null) queryParams['concept_id'] = conceptId;
      if (difficulty != null) queryParams['difficulty'] = difficulty;

      final response = await _api.get(
        ApiConstants.nextQuestion,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );
      return QuestionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Fetch full question details including correct answer and explanations.
  Future<QuestionDetail> getQuestionDetail(int id) async {
    try {
      final response = await _api.get(ApiConstants.questionDetail(id));
      return QuestionDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Request a hint for the given question.
  ///
  /// Returns `null` if no hint is available.
  Future<String?> getHint(int questionId) async {
    try {
      final response = await _api.get(ApiConstants.questionHint(questionId));
      return response.data['hint'] as String?;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _handleError(e);
    }
  }

  /// Submit the student's attempt and receive the graded result.
  Future<AttemptResult> submitAttempt({
    required int questionId,
    required String selectedOption,
    required int timeTakenSeconds,
    required bool wasGuessed,
    required bool hintUsed,
  }) async {
    try {
      final response = await _api.post(
        ApiConstants.createAttempt,
        data: {
          'question_id': questionId,
          'selected_option': selectedOption.toLowerCase(),
          'time_taken_seconds': timeTakenSeconds,
          'was_guessed': wasGuessed,
          'hint_used': hintUsed,
        },
      );
      return AttemptResult.fromJson(response.data as Map<String, dynamic>);
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
      switch (e.response!.statusCode) {
        case 404:
          return Exception(
              'No questions available right now. Try again later.');
        case 422:
          return Exception('Invalid request. Please try again.');
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
