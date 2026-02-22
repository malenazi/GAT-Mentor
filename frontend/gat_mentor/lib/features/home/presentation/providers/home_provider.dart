import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/plan_repository.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class HomeState {
  final Map<String, dynamic>? plan;
  final Map<String, dynamic>? streak;
  final bool isLoading;
  final String? error;

  const HomeState({
    this.plan,
    this.streak,
    this.isLoading = false,
    this.error,
  });

  /// Convenience getter for the list of plan items.
  List<Map<String, dynamic>> get planItems {
    if (plan == null) return [];
    final items = plan!['items'] ?? plan!['plan_items'] ?? [];
    if (items is List) {
      return items.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Number of completed items.
  int get completedCount =>
      planItems.where((i) => i['completed'] == true).length;

  /// Total items.
  int get totalCount => planItems.length;

  /// Current streak count.
  int get streakCount =>
      (streak?['current_streak'] as int?) ??
      (streak?['streak'] as int?) ??
      0;

  HomeState copyWith({
    Map<String, dynamic>? plan,
    Map<String, dynamic>? streak,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      plan: plan ?? this.plan,
      streak: streak ?? this.streak,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class HomeNotifier extends StateNotifier<HomeState> {
  final PlanRepository _repository;

  HomeNotifier(this._repository) : super(const HomeState());

  /// Loads today's plan from the backend.
  Future<void> loadTodayPlan() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final plan = await _repository.getTodayPlan();
      state = state.copyWith(plan: plan, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Marks a plan item as complete and refreshes the plan.
  Future<void> completePlanItem(int itemId) async {
    try {
      await _repository.completePlanItem(itemId);
      // Optimistically update the local state.
      if (state.plan != null) {
        final updatedItems = state.planItems.map((item) {
          if (item['id'] == itemId) {
            return {...item, 'completed': true};
          }
          return item;
        }).toList();
        final updatedPlan = Map<String, dynamic>.from(state.plan!);
        // Preserve whichever key the backend uses.
        if (updatedPlan.containsKey('items')) {
          updatedPlan['items'] = updatedItems;
        } else {
          updatedPlan['plan_items'] = updatedItems;
        }
        state = state.copyWith(plan: updatedPlan);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Loads the current streak information.
  Future<void> loadStreak() async {
    try {
      final streak = await _repository.getStreak();
      state = state.copyWith(streak: streak);
    } catch (e) {
      // Streak load failure is non-critical; keep existing state.
      state = state.copyWith(error: e.toString());
    }
  }

  /// Convenience: load both plan and streak in parallel.
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _repository.getTodayPlan(),
        _repository.getStreak(),
      ]);
      state = state.copyWith(
        plan: results[0],
        streak: results[1],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final repository = ref.watch(planRepositoryProvider);
  return HomeNotifier(repository);
});
