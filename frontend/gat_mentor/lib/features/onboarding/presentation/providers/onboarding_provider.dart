import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/onboarding_repository.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class OnboardingState {
  final String level;
  final String studyFocus;
  final DateTime? examDate;
  final int dailyMinutes;
  final int targetScore;
  final List<Map<String, dynamic>> diagnosticQuestions;
  final Map<String, dynamic>? results;
  final Map<int, int> selectedAnswers; // questionIndex -> choiceIndex
  final bool isLoading;
  final String? error;

  const OnboardingState({
    this.level = 'average',
    this.studyFocus = 'both',
    this.examDate,
    this.dailyMinutes = 45,
    this.targetScore = 70,
    this.diagnosticQuestions = const [],
    this.results,
    this.selectedAnswers = const {},
    this.isLoading = false,
    this.error,
  });

  OnboardingState copyWith({
    String? level,
    String? studyFocus,
    DateTime? examDate,
    int? dailyMinutes,
    int? targetScore,
    List<Map<String, dynamic>>? diagnosticQuestions,
    Map<String, dynamic>? results,
    Map<int, int>? selectedAnswers,
    bool? isLoading,
    String? error,
  }) {
    return OnboardingState(
      level: level ?? this.level,
      studyFocus: studyFocus ?? this.studyFocus,
      examDate: examDate ?? this.examDate,
      dailyMinutes: dailyMinutes ?? this.dailyMinutes,
      targetScore: targetScore ?? this.targetScore,
      diagnosticQuestions: diagnosticQuestions ?? this.diagnosticQuestions,
      results: results ?? this.results,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final OnboardingRepository _repository;

  OnboardingNotifier(this._repository) : super(const OnboardingState());

  // -- Profile fields -------------------------------------------------------

  void setLevel(String level) {
    state = state.copyWith(level: level);
  }

  void setStudyFocus(String focus) {
    state = state.copyWith(studyFocus: focus);
  }

  void setExamDate(DateTime? date) {
    state = state.copyWith(examDate: date);
  }

  void setDailyMinutes(int minutes) {
    state = state.copyWith(dailyMinutes: minutes);
  }

  void setTargetScore(int score) {
    state = state.copyWith(targetScore: score);
  }

  // -- Answer tracking ------------------------------------------------------

  void selectAnswer(int questionIndex, int choiceIndex) {
    final updated = Map<int, int>.from(state.selectedAnswers);
    updated[questionIndex] = choiceIndex;
    state = state.copyWith(selectedAnswers: updated);
  }

  // -- API actions ----------------------------------------------------------

  /// Sends the profile preferences to the backend.
  Future<bool> setProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final examDateStr = state.examDate?.toIso8601String().split('T').first;
      await _repository.setProfile(
        level: state.level,
        studyFocus: state.studyFocus,
        examDate: examDateStr,
        dailyMinutes: state.dailyMinutes,
        targetScore: state.targetScore,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Loads the diagnostic questions from the backend.
  Future<void> loadDiagnostic() async {
    state = state.copyWith(isLoading: true, error: null, selectedAnswers: {});
    try {
      final questions = await _repository.getDiagnosticQuestions();
      state = state.copyWith(
        diagnosticQuestions: questions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Submits the diagnostic answers and stores the result.
  Future<bool> submitDiagnostic() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      const optionLetters = ['a', 'b', 'c', 'd'];
      final answers = state.selectedAnswers.entries.map((e) {
        final question = state.diagnosticQuestions[e.key];
        return {
          'question_id': question['id'],
          'selected_option': optionLetters[e.value],
        };
      }).toList();

      final result = await _repository.submitDiagnostic(answers: answers);
      state = state.copyWith(results: result, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final repository = ref.watch(onboardingRepositoryProvider);
  return OnboardingNotifier(repository);
});
