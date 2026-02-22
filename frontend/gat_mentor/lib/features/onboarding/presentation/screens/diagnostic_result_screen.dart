import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/onboarding_provider.dart';

class DiagnosticResultScreen extends ConsumerWidget {
  const DiagnosticResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final textTheme = Theme.of(context).textTheme;

    if (state.isLoading || state.results == null) {
      return const Scaffold(
        body: LoadingWidget(message: 'Analyzing your results...'),
      );
    }

    final results = state.results!;
    final overallAccuracy =
        (results['overall_accuracy'] as num?)?.toDouble() ??
            (results['accuracy'] as num?)?.toDouble() ??
            0.0;
    final recommendedLevel =
        results['recommended_level'] as String? ??
            results['level'] as String? ??
            state.level;
    final conceptResults = _extractConceptResults(results);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
                child: Column(
                  children: [
                    // Accuracy ring
                    _AccuracyRing(accuracy: overallAccuracy),
                    const SizedBox(height: 24),
                    Text(
                      'Diagnostic Complete!',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getEncouragingMessage(overallAccuracy),
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Recommended level ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.08),
                        AppColors.secondary.withOpacity(0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recommended Level',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatLevel(recommendedLevel),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Concept breakdown header ────────────────────────────
            if (conceptResults.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                  child: Text(
                    'Performance by Concept',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),

            // ── Concept bars ────────────────────────────────────────
            if (conceptResults.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList.builder(
                  itemCount: conceptResults.length,
                  itemBuilder: (_, i) {
                    final concept = conceptResults[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ConceptBar(
                        name: concept['name'] as String,
                        accuracy: (concept['accuracy'] as num).toDouble(),
                      ),
                    );
                  },
                ),
              ),

            // ── Bottom padding for button ───────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),

      // ── Start Learning button ─────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.rocket_launch_outlined),
              label: const Text('Start Learning'),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _extractConceptResults(
      Map<String, dynamic> results) {
    // Shape 1: { "concepts": [{ "name": "...", "accuracy": 0.8 }, ...] }
    if (results['concepts'] is List) {
      return (results['concepts'] as List).cast<Map<String, dynamic>>();
    }
    // Shape 2: { "concept_accuracy": { "Algebra": 0.8, ... } }
    if (results['concept_accuracy'] is Map) {
      final map = results['concept_accuracy'] as Map<String, dynamic>;
      return map.entries
          .map((e) => {'name': e.key, 'accuracy': e.value})
          .toList();
    }
    // Shape 3: { "per_concept": { ... } }
    if (results['per_concept'] is Map) {
      final map = results['per_concept'] as Map<String, dynamic>;
      return map.entries
          .map((e) => {'name': e.key, 'accuracy': e.value})
          .toList();
    }
    return [];
  }

  String _formatLevel(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return 'Beginner';
      case 'average':
        return 'Average';
      case 'high':
        return 'High Scorer';
      case 'high_scorer':
        return 'High Scorer';
      default:
        return level[0].toUpperCase() + level.substring(1);
    }
  }

  String _getEncouragingMessage(double accuracy) {
    if (accuracy >= 0.8) {
      return 'Excellent performance! You have a strong foundation. '
          'Let\'s push for mastery.';
    }
    if (accuracy >= 0.5) {
      return 'Good start! We\'ve identified areas to focus on. '
          'Your personalized plan is ready.';
    }
    return 'Great job completing the diagnostic! We\'ll build your '
        'skills step by step with a tailored study plan.';
  }
}

// ==========================================================================
// Accuracy ring widget
// ==========================================================================

class _AccuracyRing extends StatelessWidget {
  final double accuracy;

  const _AccuracyRing({required this.accuracy});

  @override
  Widget build(BuildContext context) {
    final percentage = (accuracy * 100).round();
    final color = AppColors.getMasteryColor(accuracy);

    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: CircularProgressIndicator(
              value: accuracy,
              strokeWidth: 10,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Text(
                'Accuracy',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// Concept accuracy bar widget
// ==========================================================================

class _ConceptBar extends StatelessWidget {
  final String name;
  final double accuracy;

  const _ConceptBar({required this.name, required this.accuracy});

  @override
  Widget build(BuildContext context) {
    final percentage = (accuracy * 100).round();
    final color = AppColors.getMasteryColor(accuracy);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: accuracy.clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
