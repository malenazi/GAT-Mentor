import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/auth_repository.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/profile_repository.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ProfileState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final UserModel? user;
  final int streak;
  final int daysActive;
  final int totalQuestionsDone;

  const ProfileState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.user,
    this.streak = 0,
    this.daysActive = 0,
    this.totalQuestionsDone = 0,
  });

  ProfileState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    UserModel? user,
    int? streak,
    int? daysActive,
    int? totalQuestionsDone,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      user: user ?? this.user,
      streak: streak ?? this.streak,
      daysActive: daysActive ?? this.daysActive,
      totalQuestionsDone: totalQuestionsDone ?? this.totalQuestionsDone,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _profileRepo;
  final AuthRepository _authRepo;

  ProfileNotifier(this._profileRepo, this._authRepo)
      : super(const ProfileState());

  /// Load user profile and stats.
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      final results = await Future.wait([
        _authRepo.getMe(),
        _profileRepo.getDashboard(),
        _profileRepo.getCurrentStreak(),
      ]);

      final user = results[0] as UserModel;
      final dashboard = results[1] as Map<String, dynamic>;
      final streakData = results[2] as Map<String, dynamic>;

      state = state.copyWith(
        isLoading: false,
        user: user,
        totalQuestionsDone:
            (dashboard['total_questions_done'] ?? 0) as int,
        daysActive: (dashboard['days_active'] ?? 0) as int,
        streak: (streakData['current_streak'] ??
                streakData['streak'] ??
                0) as int,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Update study plan settings.
  Future<void> updatePlanSettings({
    String? examDate,
    int? dailyMinutes,
    int? targetScore,
    String? level,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      await _profileRepo.updatePlanSettings(
        examDate: examDate,
        dailyMinutes: dailyMinutes,
        targetScore: targetScore,
        level: level,
      );

      // Reload the user profile to get updated values.
      final user = await _authRepo.getMe();
      state = state.copyWith(
        isLoading: false,
        user: user,
        successMessage: 'Settings updated successfully!',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Update user profile data.
  Future<void> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    try {
      await _profileRepo.updateProfile(data);
      final user = await _authRepo.getMe();
      state = state.copyWith(
        isLoading: false,
        user: user,
        successMessage: 'Profile updated successfully!',
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
// Provider
// ---------------------------------------------------------------------------

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(
    ref.read(profileRepositoryProvider),
    ref.read(authRepositoryProvider),
  );
});
