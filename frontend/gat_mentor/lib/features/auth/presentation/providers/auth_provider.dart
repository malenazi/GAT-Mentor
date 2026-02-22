import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/secure_storage.dart';
import '../../data/auth_repository.dart';
import '../../data/models/user_model.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class AuthState {
  final bool isAuthenticated;
  final UserModel? user;
  final String? token;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.token,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    UserModel? user,
    String? token,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearUser = false,
    bool clearToken = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: clearUser ? null : (user ?? this.user),
      token: clearToken ? null : (token ?? this.token),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  String toString() =>
      'AuthState(isAuthenticated: $isAuthenticated, user: $user, '
      'isLoading: $isLoading, error: $error)';
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState()) {
    _loadFromStorage();
  }

  // ---- Public API ----------------------------------------------------------

  /// Try to resume a previous session from secure storage.
  Future<void> checkAuth() async => _loadFromStorage();

  /// Login with email and password.
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final token = await _repo.login(email, password);
      await SecureStorage.saveToken(token);
      final user = await _repo.getMe();
      state = AuthState(
        isAuthenticated: true,
        user: user,
        token: token,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _cleanMessage(e),
      );
    }
  }

  /// Register a new account.
  Future<void> register(
      String email, String password, String fullName) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final token = await _repo.register(email, password, fullName);
      await SecureStorage.saveToken(token);
      final user = await _repo.getMe();
      state = AuthState(
        isAuthenticated: true,
        user: user,
        token: token,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _cleanMessage(e),
      );
    }
  }

  /// Sign out and clear all stored credentials.
  Future<void> logout() async {
    await SecureStorage.clearAll();
    state = const AuthState();
  }

  /// Clear the current error message (e.g. after the user dismisses it).
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Refresh the user profile from the backend.
  Future<void> refreshUser() async {
    try {
      final user = await _repo.getMe();
      state = state.copyWith(user: user);
    } on Exception catch (_) {
      // Silently ignore -- the user can retry later.
    }
  }

  // ---- Private helpers -----------------------------------------------------

  Future<void> _loadFromStorage() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        state = const AuthState(); // no stored session
        return;
      }
      final user = await _repo.getMe();
      state = AuthState(
        isAuthenticated: true,
        user: user,
        token: token,
      );
    } on Exception catch (_) {
      // Token is invalid or expired -- clear it.
      await SecureStorage.deleteToken();
      state = const AuthState();
    }
  }

  String _cleanMessage(Exception e) {
    final raw = e.toString();
    // Strip the leading "Exception: " prefix that Dart adds.
    if (raw.startsWith('Exception: ')) {
      return raw.substring(11);
    }
    return raw;
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return AuthNotifier(repo);
});
