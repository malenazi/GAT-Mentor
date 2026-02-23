import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_repository.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class AdminDashboardState {
  final int totalUsers;
  final int totalQuestions;
  final int totalAttempts;
  final double avgMastery;
  final bool isLoading;
  final String? error;

  const AdminDashboardState({
    this.totalUsers = 0,
    this.totalQuestions = 0,
    this.totalAttempts = 0,
    this.avgMastery = 0.0,
    this.isLoading = false,
    this.error,
  });

  AdminDashboardState copyWith({
    int? totalUsers,
    int? totalQuestions,
    int? totalAttempts,
    double? avgMastery,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AdminDashboardState(
      totalUsers: totalUsers ?? this.totalUsers,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      avgMastery: avgMastery ?? this.avgMastery,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AdminQuestionsState {
  final List<Map<String, dynamic>> questions;
  final int total;
  final int currentPage;
  final bool isLoading;
  final String? error;

  const AdminQuestionsState({
    this.questions = const [],
    this.total = 0,
    this.currentPage = 1,
    this.isLoading = false,
    this.error,
  });

  AdminQuestionsState copyWith({
    List<Map<String, dynamic>>? questions,
    int? total,
    int? currentPage,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AdminQuestionsState(
      questions: questions ?? this.questions,
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  int get totalPages => (total / 20).ceil().clamp(1, 999);
}

// ---------------------------------------------------------------------------
// Dashboard Notifier
// ---------------------------------------------------------------------------

class AdminDashboardNotifier extends StateNotifier<AdminDashboardState> {
  final AdminRepository _repo;

  AdminDashboardNotifier(this._repo) : super(const AdminDashboardState());

  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _repo.getOverviewStats();
      state = AdminDashboardState(
        totalUsers: data['total_users'] as int? ?? 0,
        totalQuestions: data['total_questions'] as int? ?? 0,
        totalAttempts: data['total_attempts'] as int? ?? 0,
        avgMastery: (data['avg_mastery'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Questions Notifier
// ---------------------------------------------------------------------------

class AdminQuestionsNotifier extends StateNotifier<AdminQuestionsState> {
  final AdminRepository _repo;

  AdminQuestionsNotifier(this._repo) : super(const AdminQuestionsState());

  Future<void> loadQuestions({int page = 1}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _repo.getQuestions(page: page);
      final questions =
          (data['questions'] as List).cast<Map<String, dynamic>>();
      state = AdminQuestionsState(
        questions: questions,
        total: data['total'] as int? ?? 0,
        currentPage: data['page'] as int? ?? page,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> deactivateQuestion(int questionId) async {
    try {
      await _repo.deactivateQuestion(questionId);
      // Remove from local list
      final updated =
          state.questions.where((q) => q['id'] != questionId).toList();
      state = state.copyWith(
        questions: updated,
        total: state.total - 1,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void nextPage() {
    if (state.currentPage < state.totalPages) {
      loadQuestions(page: state.currentPage + 1);
    }
  }

  void previousPage() {
    if (state.currentPage > 1) {
      loadQuestions(page: state.currentPage - 1);
    }
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final adminDashboardProvider =
    StateNotifierProvider.autoDispose<AdminDashboardNotifier, AdminDashboardState>(
        (ref) {
  final repo = ref.read(adminRepositoryProvider);
  return AdminDashboardNotifier(repo);
});

final adminQuestionsProvider =
    StateNotifierProvider.autoDispose<AdminQuestionsNotifier, AdminQuestionsState>(
        (ref) {
  final repo = ref.read(adminRepositoryProvider);
  return AdminQuestionsNotifier(repo);
});
