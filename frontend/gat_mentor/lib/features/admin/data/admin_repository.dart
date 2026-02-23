import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/data/auth_repository.dart';

class AdminRepository {
  final ApiClient _client;

  AdminRepository(this._client);

  /// GET /admin/stats/overview
  Future<Map<String, dynamic>> getOverviewStats() async {
    final resp = await _client.get('/admin/stats/overview');
    return resp.data as Map<String, dynamic>;
  }

  /// GET /admin/questions/?page=&per_page=&topic_id=&concept_id=
  Future<Map<String, dynamic>> getQuestions({
    int page = 1,
    int perPage = 20,
    int? topicId,
    int? conceptId,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (topicId != null) params['topic_id'] = topicId;
    if (conceptId != null) params['concept_id'] = conceptId;

    final resp = await _client.get('/admin/questions/', queryParams: params);
    return resp.data as Map<String, dynamic>;
  }

  /// DELETE /admin/questions/{id} — soft delete (deactivate)
  Future<void> deactivateQuestion(int questionId) async {
    await _client.delete('/admin/questions/$questionId');
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final client = ref.read(apiClientProvider);
  return AdminRepository(client);
});
