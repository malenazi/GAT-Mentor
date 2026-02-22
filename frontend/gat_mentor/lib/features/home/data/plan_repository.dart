import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../auth/data/auth_repository.dart';

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return PlanRepository(ref.read(apiClientProvider));
});

class PlanRepository {
  final ApiClient _api;

  PlanRepository(this._api);

  /// Fetches today's personalized study plan.
  Future<Map<String, dynamic>> getTodayPlan() async {
    final response = await _api.get(ApiConstants.todayPlan);
    return response.data as Map<String, dynamic>;
  }

  /// Marks a single plan item as completed.
  Future<void> completePlanItem(int itemId) async {
    await _api.post(ApiConstants.completePlanItem(itemId));
  }

  /// Fetches the current streak information.
  Future<Map<String, dynamic>> getStreak() async {
    final response = await _api.get(ApiConstants.currentStreak);
    return response.data as Map<String, dynamic>;
  }
}
