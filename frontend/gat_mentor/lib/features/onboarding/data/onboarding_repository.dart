import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(ApiClient());
});

class OnboardingRepository {
  final ApiClient _api;

  OnboardingRepository(this._api);

  /// Saves the user's onboarding profile preferences.
  Future<Map<String, dynamic>> setProfile({
    required String level,
    required String studyFocus,
    required String? examDate,
    required int dailyMinutes,
    required int targetScore,
  }) async {
    final response = await _api.post(
      ApiConstants.onboardingProfile,
      data: {
        'level': level,
        'study_focus': studyFocus,
        'exam_date': examDate,
        'daily_minutes': dailyMinutes,
        'target_score': targetScore,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Fetches the diagnostic assessment questions.
  Future<List<Map<String, dynamic>>> getDiagnosticQuestions() async {
    final response = await _api.get(ApiConstants.diagnosticQuestions);
    final data = response.data;
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    // Handle wrapped response: { "questions": [...] }
    if (data is Map<String, dynamic> && data.containsKey('questions')) {
      return (data['questions'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Submits the user's diagnostic answers and returns the result summary.
  Future<Map<String, dynamic>> submitDiagnostic({
    required List<Map<String, dynamic>> answers,
  }) async {
    final response = await _api.post(
      ApiConstants.diagnosticSubmit,
      data: {'answers': answers},
    );
    return response.data as Map<String, dynamic>;
  }
}
