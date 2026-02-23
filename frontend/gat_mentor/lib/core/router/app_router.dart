import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/onboarding/presentation/screens/profile_setup_screen.dart';
import '../../features/onboarding/presentation/screens/diagnostic_test_screen.dart';
import '../../features/onboarding/presentation/screens/diagnostic_result_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/practice/presentation/screens/practice_screen.dart';
import '../../features/practice/presentation/screens/solution_screen.dart';
import '../../features/review/presentation/screens/review_queue_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/exam_simulation/presentation/screens/simulation_setup_screen.dart';
import '../../features/exam_simulation/presentation/screens/simulation_screen.dart';
import '../../features/exam_simulation/presentation/screens/simulation_result_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/plan_settings_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_questions_screen.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../../shared/widgets/admin_nav_bar.dart';

/// Converts a Riverpod [StateNotifierProvider] into a [Listenable] so GoRouter
/// can use it as a [refreshListenable] without recreating the entire router.
class _AuthRefreshNotifier extends ChangeNotifier {
  late final ProviderSubscription<AuthState> _subscription;

  _AuthRefreshNotifier(Ref ref) {
    _subscription = ref.listen<AuthState>(authProvider, (_, __) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);

  ref.onDispose(() => refreshNotifier.dispose());

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      // Read the CURRENT auth state at redirect time (not during provider creation).
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isOnboarded = authState.user?.onboardingComplete ?? false;
      final isAdmin = authState.user?.isAdmin ?? false;
      final path = state.matchedLocation;
      final isAuthRoute = path == '/login' || path == '/register';
      final isOnboardingRoute = path.startsWith('/onboarding');
      final isAdminRoute = path.startsWith('/admin');

      // Still loading from storage — don't redirect yet.
      if (authState.isLoading) return null;

      // Not logged in — force to login.
      if (!isLoggedIn && !isAuthRoute) return '/login';

      // Logged in but not onboarded (students only) — force onboarding.
      if (isLoggedIn && !isAdmin && !isOnboarded && !isOnboardingRoute) {
        return '/onboarding';
      }

      // Logged in + onboarded (or admin) trying to visit auth/onboarding pages.
      if (isLoggedIn && (isOnboarded || isAdmin) && (isAuthRoute || isOnboardingRoute)) {
        return isAdmin ? '/admin' : '/home';
      }

      // Admin user trying to access student routes — redirect to admin.
      if (isLoggedIn && isAdmin && !isAdminRoute && !isAuthRoute && !isOnboardingRoute) {
        return '/admin';
      }

      // Student trying to access admin routes — redirect to home.
      if (isLoggedIn && !isAdmin && isAdminRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
          path: '/onboarding',
          builder: (_, __) => const ProfileSetupScreen()),
      GoRoute(
          path: '/onboarding/diagnostic',
          builder: (_, __) => const DiagnosticTestScreen()),
      GoRoute(
          path: '/onboarding/result',
          builder: (_, __) => const DiagnosticResultScreen()),

      // ── Student shell routes ──────────────────────────────────────
      ShellRoute(
        builder: (_, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(
              path: '/practice', builder: (_, __) => const PracticeScreen()),
          GoRoute(
            path: '/practice/solution/:id',
            builder: (_, state) => SolutionScreen(
              questionId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
              path: '/review',
              builder: (_, __) => const ReviewQueueScreen()),
          GoRoute(
              path: '/dashboard',
              builder: (_, __) => const DashboardScreen()),
          GoRoute(
              path: '/simulation',
              builder: (_, __) => const SimulationSetupScreen()),
          GoRoute(
            path: '/simulation/run/:id',
            builder: (_, state) => SimulationScreen(
              sessionId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/simulation/result/:id',
            builder: (_, state) => SimulationResultScreen(
              sessionId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
              path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(
              path: '/profile/settings',
              builder: (_, __) => const PlanSettingsScreen()),
        ],
      ),

      // ── Admin shell routes ────────────────────────────────────────
      ShellRoute(
        builder: (_, state, child) => AdminScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(
              path: '/admin',
              builder: (_, __) => const AdminDashboardScreen()),
          GoRoute(
              path: '/admin/questions',
              builder: (_, __) => const AdminQuestionsScreen()),
          GoRoute(
              path: '/admin/profile',
              builder: (_, __) => const ProfileScreen()),
          GoRoute(
              path: '/admin/profile/settings',
              builder: (_, __) => const PlanSettingsScreen()),
        ],
      ),
    ],
  );
});
