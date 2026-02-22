import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/review_repository.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ReviewState {
  final List<ReviewItem> items;
  final Set<int> expandedIds; // attempt IDs that are currently expanded
  final bool isLoading;
  final String? error;

  const ReviewState({
    this.items = const [],
    this.expandedIds = const {},
    this.isLoading = false,
    this.error,
  });

  ReviewState copyWith({
    List<ReviewItem>? items,
    Set<int>? expandedIds,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ReviewState(
      items: items ?? this.items,
      expandedIds: expandedIds ?? this.expandedIds,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isEmpty => items.isEmpty && !isLoading;

  int get count => items.length;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ReviewNotifier extends StateNotifier<ReviewState> {
  final ReviewRepository _repo;

  ReviewNotifier(this._repo) : super(const ReviewState());

  /// Load the review queue from the backend.
  Future<void> loadQueue() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final items = await _repo.getReviewQueue();
      state = state.copyWith(items: items, isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Toggle the expanded state of a review item card.
  void toggleExpanded(int attemptId) {
    final expanded = Set<int>.from(state.expandedIds);
    if (expanded.contains(attemptId)) {
      expanded.remove(attemptId);
    } else {
      expanded.add(attemptId);
    }
    state = state.copyWith(expandedIds: expanded);
  }

  /// Mark a review item as "Got it" (correct during review).
  Future<void> markGotIt(int attemptId, {int timeTakenSeconds = 0}) async {
    try {
      await _repo.markReviewed(
        attemptId: attemptId,
        gotCorrect: true,
        timeTakenSeconds: timeTakenSeconds,
      );
      // Remove from local list
      final updatedItems =
          state.items.where((i) => i.attemptId != attemptId).toList();
      final updatedExpanded = Set<int>.from(state.expandedIds)
        ..remove(attemptId);
      state = state.copyWith(items: updatedItems, expandedIds: updatedExpanded);
    } on Exception catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Mark a review item as "Still confused" (wrong during review).
  Future<void> markStillConfused(int attemptId,
      {int timeTakenSeconds = 0}) async {
    try {
      await _repo.markReviewed(
        attemptId: attemptId,
        gotCorrect: false,
        timeTakenSeconds: timeTakenSeconds,
      );
      // Remove from local list (it will reappear at the next scheduled time)
      final updatedItems =
          state.items.where((i) => i.attemptId != attemptId).toList();
      final updatedExpanded = Set<int>.from(state.expandedIds)
        ..remove(attemptId);
      state = state.copyWith(items: updatedItems, expandedIds: updatedExpanded);
    } on Exception catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Classify a mistake for a review item.
  Future<void> classifyMistake(int attemptId, String mistakeType) async {
    try {
      await _repo.classifyMistake(attemptId, mistakeType);
      // Update the local item
      final updatedItems = state.items.map((item) {
        if (item.attemptId == attemptId) {
          return ReviewItem(
            attemptId: item.attemptId,
            questionId: item.questionId,
            questionSnippet: item.questionSnippet,
            conceptName: item.conceptName,
            topicName: item.topicName,
            selectedOption: item.selectedOption,
            correctOption: item.correctOption,
            explanation: item.explanation,
            whyWrong: item.whyWrong,
            mistakeType: mistakeType,
            reviewCount: item.reviewCount,
            scheduledFor: item.scheduledFor,
          );
        }
        return item;
      }).toList();
      state = state.copyWith(items: updatedItems);
    } on Exception catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final reviewProvider =
    StateNotifierProvider.autoDispose<ReviewNotifier, ReviewState>((ref) {
  final repo = ref.read(reviewRepositoryProvider);
  return ReviewNotifier(repo);
});
