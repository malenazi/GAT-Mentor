import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/session_repository.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class SimulationState {
  final bool isLoading;
  final String? error;
  final int? sessionId;
  final List<Map<String, dynamic>> questions;
  final int currentIndex;
  final Map<int, int> answers; // questionId -> selectedOptionIndex
  final int timeRemaining; // seconds
  final bool isComplete;
  final Map<String, dynamic>? result;

  const SimulationState({
    this.isLoading = false,
    this.error,
    this.sessionId,
    this.questions = const [],
    this.currentIndex = 0,
    this.answers = const {},
    this.timeRemaining = 0,
    this.isComplete = false,
    this.result,
  });

  int get totalQuestions => questions.length;

  bool get isLastQuestion => currentIndex >= totalQuestions - 1;

  Map<String, dynamic>? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  bool get hasAnsweredCurrent {
    final q = currentQuestion;
    if (q == null) return false;
    return answers.containsKey(q['id']);
  }

  SimulationState copyWith({
    bool? isLoading,
    String? error,
    int? sessionId,
    List<Map<String, dynamic>>? questions,
    int? currentIndex,
    Map<int, int>? answers,
    int? timeRemaining,
    bool? isComplete,
    Map<String, dynamic>? result,
  }) {
    return SimulationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      sessionId: sessionId ?? this.sessionId,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      isComplete: isComplete ?? this.isComplete,
      result: result ?? this.result,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class SimulationNotifier extends StateNotifier<SimulationState> {
  final SessionRepository _repo;
  Timer? _timer;

  SimulationNotifier(this._repo) : super(const SimulationState());

  /// Start a new simulation session.
  Future<void> startSession({
    required String type,
    required int questionCount,
    int? topicId,
    String? difficulty,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.startSession(
        type: type,
        questionCount: questionCount,
        topicId: topicId,
        difficulty: difficulty,
      );

      final sessionId = data['id'] as int;
      final questions = (data['questions'] as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // Calculate time: ~90 seconds per question
      final totalTime = questionCount * 90;

      state = SimulationState(
        sessionId: sessionId,
        questions: questions,
        currentIndex: 0,
        answers: {},
        timeRemaining: totalTime,
        isComplete: false,
      );

      _startTimer();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Load an existing session by ID.
  Future<void> loadSession(int sessionId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.getSession(sessionId);
      final questions = (data['questions'] as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final totalTime = questions.length * 90;

      state = SimulationState(
        sessionId: sessionId,
        questions: questions,
        currentIndex: 0,
        answers: {},
        timeRemaining: totalTime,
        isComplete: false,
      );

      _startTimer();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Record the answer for the current question.
  void answerQuestion(int questionId, int selectedIndex) {
    final updatedAnswers = Map<int, int>.from(state.answers);
    updatedAnswers[questionId] = selectedIndex;
    state = state.copyWith(answers: updatedAnswers);
  }

  /// Move to the next question.
  void nextQuestion() {
    if (state.currentIndex < state.totalQuestions - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  /// Move to the previous question.
  void previousQuestion() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  /// Submit all answers and get results.
  Future<void> submitAll() async {
    _stopTimer();
    state = state.copyWith(isLoading: true, error: null);
    try {
      const optionLetters = ['a', 'b', 'c', 'd'];
      final answersList = state.answers.entries.map((entry) {
        // Convert int index (0-3) to letter ('a'-'d') for the backend
        final letter = entry.value >= 0 && entry.value < optionLetters.length
            ? optionLetters[entry.value]
            : 'a';
        return {
          'question_id': entry.key,
          'selected_option': letter,
        };
      }).toList();

      final result = await _repo.submitSession(
        state.sessionId!,
        answersList,
      );

      state = state.copyWith(
        isLoading: false,
        isComplete: true,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Reset to initial state.
  void reset() {
    _stopTimer();
    state = const SimulationState();
  }

  // ---------------------------------------------------------------------------
  // Timer
  // ---------------------------------------------------------------------------

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.timeRemaining <= 1) {
        _stopTimer();
        submitAll();
      } else {
        state = state.copyWith(timeRemaining: state.timeRemaining - 1);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
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

final simulationProvider =
    StateNotifierProvider<SimulationNotifier, SimulationState>((ref) {
  return SimulationNotifier(ref.read(sessionRepositoryProvider));
});
