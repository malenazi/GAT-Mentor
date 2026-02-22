import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/stats_repository.dart';

// ---------------------------------------------------------------------------
// Helper classes
// ---------------------------------------------------------------------------

class TopicPerformance {
  final String topicName;
  final double mastery;
  final double accuracy;
  final int totalAttempts;
  final int conceptCount;
  final int masteredCount;
  final List<Map<String, dynamic>> concepts;

  const TopicPerformance({
    required this.topicName,
    required this.mastery,
    required this.accuracy,
    required this.totalAttempts,
    required this.conceptCount,
    required this.masteredCount,
    required this.concepts,
  });
}

class FocusRecommendation {
  final Map<String, dynamic> concept;
  final String message;
  final String priority; // "high" | "medium" | "low"

  const FocusRecommendation({
    required this.concept,
    required this.message,
    required this.priority,
  });
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class DashboardState {
  final bool isLoading;
  final String? error;

  // Summary
  final int totalQuestionsDone;
  final int totalCorrect;
  final double overallAccuracy;
  final double avgTime;
  final int streak;
  final int longestStreak;
  final int totalStudyMinutes;
  final List<Map<String, dynamic>> masterySummary;
  final List<Map<String, dynamic>> weakestConcepts;

  // Mastery map
  final List<Map<String, dynamic>> masteryMap;

  // Trends
  final List<Map<String, dynamic>> trends;

  const DashboardState({
    this.isLoading = false,
    this.error,
    this.totalQuestionsDone = 0,
    this.totalCorrect = 0,
    this.overallAccuracy = 0,
    this.avgTime = 0,
    this.streak = 0,
    this.longestStreak = 0,
    this.totalStudyMinutes = 0,
    this.masterySummary = const [],
    this.weakestConcepts = const [],
    this.masteryMap = const [],
    this.trends = const [],
  });

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    int? totalQuestionsDone,
    int? totalCorrect,
    double? overallAccuracy,
    double? avgTime,
    int? streak,
    int? longestStreak,
    int? totalStudyMinutes,
    List<Map<String, dynamic>>? masterySummary,
    List<Map<String, dynamic>>? weakestConcepts,
    List<Map<String, dynamic>>? masteryMap,
    List<Map<String, dynamic>>? trends,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalQuestionsDone: totalQuestionsDone ?? this.totalQuestionsDone,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      overallAccuracy: overallAccuracy ?? this.overallAccuracy,
      avgTime: avgTime ?? this.avgTime,
      streak: streak ?? this.streak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalStudyMinutes: totalStudyMinutes ?? this.totalStudyMinutes,
      masterySummary: masterySummary ?? this.masterySummary,
      weakestConcepts: weakestConcepts ?? this.weakestConcepts,
      masteryMap: masteryMap ?? this.masteryMap,
      trends: trends ?? this.trends,
    );
  }

  // ---- Computed getters ---------------------------------------------------

  List<TopicPerformance> get topicPerformances {
    return masteryMap.map((topic) {
      final topicName = topic['topic_name'] as String? ?? '';
      final concepts = (topic['concepts'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];

      // Find topic-level mastery from masterySummary
      final summaryEntry = masterySummary.cast<Map<String, dynamic>?>().firstWhere(
            (s) => s?['topic_name'] == topicName,
            orElse: () => null,
          );
      final mastery = (summaryEntry?['mastery'] ?? 0).toDouble();

      // Compute per-topic accuracy and attempts from concept data
      double avgAccuracy = 0;
      int totalAttempts = 0;
      int masteredCount = 0;

      if (concepts.isNotEmpty) {
        double accSum = 0;
        for (final c in concepts) {
          final cMastery = (c['mastery'] ?? 0).toDouble();
          final cAccuracy = (c['accuracy'] ?? 0).toDouble();
          accSum += cAccuracy;
          totalAttempts += (c['total_attempts'] ?? 0) as int;
          if (cMastery >= 0.8) masteredCount++;
        }
        avgAccuracy = accSum / concepts.length;
      }

      return TopicPerformance(
        topicName: topicName,
        mastery: mastery.clamp(0.0, 1.0),
        accuracy: avgAccuracy.clamp(0.0, 1.0),
        totalAttempts: totalAttempts,
        conceptCount: concepts.length,
        masteredCount: masteredCount,
        concepts: concepts,
      );
    }).toList();
  }

  List<FocusRecommendation> get focusRecommendations {
    return weakestConcepts.take(3).map((concept) {
      final mastery = (concept['mastery'] ?? 0).toDouble();
      final accuracy = (concept['accuracy'] ?? 0).toDouble();
      final attempts = (concept['total_attempts'] ?? 0) as int;
      final name =
          concept['concept_name'] as String? ?? concept['name'] as String? ?? '';

      String message;
      String priority;

      if (attempts == 0) {
        message = "Start here! You haven't tried any $name questions yet.";
        priority = 'high';
      } else if (mastery < 0.3 && accuracy < 0.4) {
        message = 'Needs work. Review the $name fundamentals.';
        priority = 'high';
      } else if (mastery < 0.3) {
        message =
            "Getting some right! Practice more $name for consistency.";
        priority = 'high';
      } else if (mastery < 0.6) {
        message =
            "Almost there! A few more $name sessions will nail it.";
        priority = 'medium';
      } else {
        message = 'Keep it up! You\'re close to mastering $name.';
        priority = 'low';
      }

      return FocusRecommendation(
        concept: concept,
        message: message,
        priority: priority,
      );
    }).toList();
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class DashboardNotifier extends StateNotifier<DashboardState> {
  final StatsRepository _repo;

  DashboardNotifier(this._repo) : super(const DashboardState());

  /// Load all dashboard data in parallel.
  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _repo.getDashboard(),
        _repo.getMasteryMap(),
        _repo.getTrends(7),
      ]);

      final dashboard = results[0] as Map<String, dynamic>;
      final mastery = results[1] as List<dynamic>;
      final trends = results[2] as List<dynamic>;

      // Backend returns accuracy as 0.0-1.0, convert to percentage for display
      final rawAccuracy = (dashboard['overall_accuracy'] ?? 0).toDouble();

      // Backend returns mastery_summary as {"TopicName": 0.5, ...} (a map),
      // convert to list of maps for the UI
      final rawMastery = dashboard['mastery_summary'];
      List<Map<String, dynamic>> masterySummaryList = [];
      if (rawMastery is Map) {
        masterySummaryList = rawMastery.entries
            .map((e) => <String, dynamic>{
                  'topic_name': e.key,
                  'mastery': e.value,
                })
            .toList();
      } else if (rawMastery is List) {
        masterySummaryList = rawMastery
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      state = state.copyWith(
        isLoading: false,
        totalQuestionsDone: (dashboard['total_questions_done'] ?? 0) as int,
        totalCorrect: (dashboard['total_correct'] ?? 0) as int,
        overallAccuracy: rawAccuracy <= 1.0 ? rawAccuracy * 100 : rawAccuracy,
        avgTime:
            (dashboard['avg_time_per_question'] ?? dashboard['avg_time'] ?? 0)
                .toDouble(),
        streak:
            (dashboard['current_streak'] ?? dashboard['streak'] ?? 0) as int,
        longestStreak: (dashboard['longest_streak'] ?? 0) as int,
        totalStudyMinutes: (dashboard['total_study_minutes'] ?? 0) as int,
        masterySummary: masterySummaryList,
        weakestConcepts: (dashboard['weakest_concepts'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
        masteryMap: mastery
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        trends: trends
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
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

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref.read(statsRepositoryProvider));
});
