import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../auth/data/auth_repository.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

/// A single item in the review queue -- a past mistake due for review.
class ReviewItem {
  final int attemptId;
  final int questionId;
  final String questionSnippet;
  final String conceptName;
  final String topicName;
  final String selectedOption;
  final String correctOption;
  final String? explanation;
  final String? whyWrong;
  final String? mistakeType; // 'conceptual', 'careless', 'time_pressure', etc.
  final int reviewCount; // how many times this has been reviewed
  final String? scheduledFor; // ISO date string

  const ReviewItem({
    required this.attemptId,
    required this.questionId,
    required this.questionSnippet,
    required this.conceptName,
    required this.topicName,
    required this.selectedOption,
    required this.correctOption,
    this.explanation,
    this.whyWrong,
    this.mistakeType,
    required this.reviewCount,
    this.scheduledFor,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      attemptId: json['attempt_id'] as int,
      questionId: json['question_id'] as int,
      questionSnippet: json['question_snippet'] as String? ?? json['question_text'] as String? ?? '',
      conceptName: json['concept_name'] as String? ?? '',
      topicName: json['topic_name'] as String? ?? '',
      selectedOption: json['selected_option'] as String,
      correctOption: json['correct_option'] as String,
      explanation: json['explanation'] as String?,
      whyWrong: json['why_wrong'] as String?,
      mistakeType: json['mistake_type'] as String?,
      reviewCount: json['review_count'] as int? ?? 0,
      scheduledFor: json['scheduled_for'] as String? ?? json['next_review_date'] as String?,
    );
  }

  /// Human-readable label for the mistake type.
  String get mistakeTypeLabel {
    switch (mistakeType) {
      case 'conceptual':
        return 'Conceptual';
      case 'careless':
        return 'Careless';
      case 'time_pressure':
        return 'Time Pressure';
      case 'misread':
        return 'Misread';
      case 'guessed':
        return 'Guessed';
      default:
        return 'Unclassified';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewItem &&
          runtimeType == other.runtimeType &&
          attemptId == other.attemptId;

  @override
  int get hashCode => attemptId.hashCode;
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.read(apiClientProvider));
});

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

class ReviewRepository {
  final ApiClient _api;

  ReviewRepository(this._api);

  /// Fetch the list of mistakes due for review.
  Future<List<ReviewItem>> getReviewQueue() async {
    try {
      final response = await _api.get(ApiConstants.reviewQueue);
      final data = response.data;
      // Backend wraps in {"reviews": [...], "count": N}
      final List<dynamic> list;
      if (data is Map<String, dynamic> && data.containsKey('reviews')) {
        list = data['reviews'] as List<dynamic>;
      } else if (data is List) {
        list = data;
      } else {
        list = [];
      }
      return list
          .map((e) => ReviewItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get the count of items currently in the review queue.
  Future<int> getReviewCount() async {
    try {
      final response = await _api.get(ApiConstants.reviewCount);
      return response.data['count'] as int? ?? 0;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Classify a mistake (e.g., conceptual, careless, time_pressure).
  Future<void> classifyMistake(int attemptId, String mistakeType) async {
    try {
      await _api.post(
        ApiConstants.classifyMistake(attemptId),
        data: {'mistake_type': mistakeType},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Mark a review item as reviewed.
  ///
  /// [gotCorrect] indicates whether the student answered correctly during
  /// the review session. This feeds back into the spaced-repetition scheduler.
  Future<void> markReviewed({
    required int attemptId,
    required bool gotCorrect,
    required int timeTakenSeconds,
  }) async {
    try {
      await _api.post(
        ApiConstants.markReviewed(attemptId),
        data: {
          'got_correct': gotCorrect,
          'time_taken_seconds': timeTakenSeconds,
        },
      );
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
          return Exception('Review item not found.');
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
