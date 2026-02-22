import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/attempt_model.dart';
import '../../data/models/question_model.dart';
import '../../data/question_repository.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class PracticeState {
  final QuestionModel? question;
  final String? selectedOption; // 'A', 'B', 'C', or 'D'
  final bool isSubmitted;
  final int timeElapsed; // seconds since question was loaded
  final bool hintRevealed;
  final String? hintText;
  final bool wasGuessed;
  final AttemptResult? attemptResult;
  final bool isLoading;
  final String? error;

  const PracticeState({
    this.question,
    this.selectedOption,
    this.isSubmitted = false,
    this.timeElapsed = 0,
    this.hintRevealed = false,
    this.hintText,
    this.wasGuessed = false,
    this.attemptResult,
    this.isLoading = false,
    this.error,
  });

  PracticeState copyWith({
    QuestionModel? question,
    String? selectedOption,
    bool? isSubmitted,
    int? timeElapsed,
    bool? hintRevealed,
    String? hintText,
    bool? wasGuessed,
    AttemptResult? attemptResult,
    bool? isLoading,
    String? error,
    // Allow explicitly clearing nullable fields
    bool clearSelectedOption = false,
    bool clearAttemptResult = false,
    bool clearError = false,
    bool clearHintText = false,
  }) {
    return PracticeState(
      question: question ?? this.question,
      selectedOption:
          clearSelectedOption ? null : (selectedOption ?? this.selectedOption),
      isSubmitted: isSubmitted ?? this.isSubmitted,
      timeElapsed: timeElapsed ?? this.timeElapsed,
      hintRevealed: hintRevealed ?? this.hintRevealed,
      hintText: clearHintText ? null : (hintText ?? this.hintText),
      wasGuessed: wasGuessed ?? this.wasGuessed,
      attemptResult:
          clearAttemptResult ? null : (attemptResult ?? this.attemptResult),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Whether the student can submit their answer.
  bool get canSubmit =>
      selectedOption != null && !isSubmitted && !isLoading && question != null;

  /// Whether we are currently showing the post-submission feedback.
  bool get showingFeedback => isSubmitted && attemptResult != null;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class PracticeNotifier extends StateNotifier<PracticeState> {
  final QuestionRepository _repo;
  Timer? _timer;

  PracticeNotifier(this._repo) : super(const PracticeState());

  // ---- Timer management ---------------------------------------------------

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !state.isSubmitted) {
        state = state.copyWith(timeElapsed: state.timeElapsed + 1);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ---- Actions ------------------------------------------------------------

  /// Load the next adaptive question from the backend.
  Future<void> loadNextQuestion({
    int? topicId,
    int? conceptId,
    int? difficulty,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSelectedOption: true,
      clearAttemptResult: true,
      clearHintText: true,
      isSubmitted: false,
      hintRevealed: false,
      wasGuessed: false,
      timeElapsed: 0,
    );

    try {
      final question = await _repo.getNextQuestion(
        topicId: topicId,
        conceptId: conceptId,
        difficulty: difficulty,
      );
      state = state.copyWith(question: question, isLoading: false);
      _startTimer();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Select an answer option. Only allowed before submission.
  void selectOption(String option) {
    if (state.isSubmitted) return;
    state = state.copyWith(selectedOption: option);
  }

  /// Toggle the "I guessed" flag.
  void toggleGuessed() {
    if (state.isSubmitted) return;
    state = state.copyWith(wasGuessed: !state.wasGuessed);
  }

  /// Reveal the hint for the current question.
  Future<void> revealHint() async {
    if (state.question == null || state.hintRevealed) return;

    try {
      final hint = await _repo.getHint(state.question!.id);
      state = state.copyWith(
        hintRevealed: true,
        hintText: hint ?? 'No hint available for this question.',
      );
    } on Exception catch (e) {
      state = state.copyWith(
        hintRevealed: true,
        hintText: 'Could not load hint: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  /// Submit the current answer to the backend for grading.
  Future<void> submitAnswer() async {
    if (!state.canSubmit) return;

    _stopTimer();
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _repo.submitAttempt(
        questionId: state.question!.id,
        selectedOption: state.selectedOption!,
        timeTakenSeconds: state.timeElapsed,
        wasGuessed: state.wasGuessed,
        hintUsed: state.hintRevealed,
      );
      state = state.copyWith(
        isSubmitted: true,
        attemptResult: result,
        isLoading: false,
      );
    } catch (e) {
      // Resume timer so the student can retry
      _startTimer();
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Reset state to prepare for the next question.
  /// Calls [loadNextQuestion] internally.
  Future<void> resetForNext({
    int? topicId,
    int? conceptId,
    int? difficulty,
  }) async {
    await loadNextQuestion(
      topicId: topicId,
      conceptId: conceptId,
      difficulty: difficulty,
    );
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final practiceProvider =
    StateNotifierProvider.autoDispose<PracticeNotifier, PracticeState>((ref) {
  final repo = ref.read(questionRepositoryProvider);
  return PracticeNotifier(repo);
});
