import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../data/session_repository.dart';
import '../providers/simulation_provider.dart';

class SimulationResultScreen extends ConsumerStatefulWidget {
  final int sessionId;

  const SimulationResultScreen({super.key, required this.sessionId});

  @override
  ConsumerState<SimulationResultScreen> createState() =>
      _SimulationResultScreenState();
}

class _SimulationResultScreenState
    extends ConsumerState<SimulationResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  Map<String, dynamic>? _result;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );

    _loadResult();
  }

  Future<void> _loadResult() async {
    // First check if result is already in provider state
    final simState = ref.read(simulationProvider);
    if (simState.result != null && simState.sessionId == widget.sessionId) {
      setState(() {
        _result = simState.result;
        _isLoading = false;
      });
      _animController.forward();
      return;
    }

    // Otherwise fetch from server
    try {
      final data = await ref
          .read(sessionRepositoryProvider)
          .getSession(widget.sessionId);
      if (mounted) {
        setState(() {
          _result = data;
          _isLoading = false;
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _buildResult(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error
  // ---------------------------------------------------------------------------

  Widget _buildError() {
    final s = S.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: Text(s.goHome),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Result
  // ---------------------------------------------------------------------------

  Widget _buildResult() {
    final s = S.of(context);
    final result = _result!;
    final totalQuestions =
        (result['total_questions'] ?? result['question_count'] ?? 0) as int;
    final correctCount = (result['correct_count'] ?? result['correct'] ?? 0) as int;
    final accuracy = totalQuestions > 0
        ? (correctCount / totalQuestions * 100)
        : 0.0;
    final timeTaken = (result['total_time_seconds'] ?? result['time_taken'] ?? result['total_time'] ?? 0);
    final timeTakenSeconds = timeTaken is int ? timeTaken : (timeTaken as double).toInt();
    final topicBreakdown =
        (result['topic_breakdown'] ?? result['breakdown'] ?? []) as List<dynamic>;

    final scorePercent =
        totalQuestions > 0 ? correctCount / totalQuestions : 0.0;
    final isGoodScore = accuracy >= 70;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Congratulations / Result header
          ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              children: [
                Icon(
                  isGoodScore
                      ? Icons.emoji_events_outlined
                      : Icons.school_outlined,
                  size: 56,
                  color:
                      isGoodScore ? AppColors.warning : AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  isGoodScore ? s.greatJob : s.keepPracticing,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isGoodScore
                      ? s.didWellSimulation
                      : s.everyAttemptStronger,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Big score circle
          CircularPercentIndicator(
            radius: 80,
            lineWidth: 12,
            percent: scorePercent.clamp(0.0, 1.0),
            animation: true,
            animationDuration: 1200,
            circularStrokeCap: CircularStrokeCap.round,
            progressColor:
                isGoodScore ? AppColors.success : AppColors.warning,
            backgroundColor:
                (isGoodScore ? AppColors.success : AppColors.warning)
                    .withOpacity(0.15),
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$correctCount/$totalQuestions',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  s.correctLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  icon: Icons.percent,
                  label: s.accuracy,
                  value: '${accuracy.toStringAsFixed(1)}%',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  icon: Icons.timer_outlined,
                  label: s.timeTaken,
                  value: _formatDuration(timeTakenSeconds),
                  color: AppColors.warning,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Per-topic breakdown
          if (topicBreakdown.isNotEmpty) ...[
            _buildTopicBreakdown(topicBreakdown),
            const SizedBox(height: 24),
          ],

          // Action buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/review'),
              icon: const Icon(Icons.rate_review_outlined),
              label: Text(s.reviewMistakes),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(simulationProvider.notifier).reset();
                context.go('/home');
              },
              icon: const Icon(Icons.home_outlined),
              label: Text(s.home),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Topic Breakdown
  // ---------------------------------------------------------------------------

  Widget _buildTopicBreakdown(List<dynamic> breakdown) {
    final s = S.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart_outlined,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  s.perTopicBreakdown,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...breakdown.map((item) {
              final topic = Map<String, dynamic>.from(item as Map);
              final name =
                  topic['topic_name'] as String? ?? topic['name'] as String? ?? '';
              final correct = (topic['correct'] ?? 0) as int;
              final total = (topic['total'] ?? 1) as int;
              final pct = total > 0 ? correct / total : 0.0;
              final color = AppColors.getMasteryColor(pct);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '$correct/$total',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearPercentIndicator(
                      padding: EdgeInsets.zero,
                      lineHeight: 8,
                      percent: pct.clamp(0.0, 1.0),
                      backgroundColor: color.withOpacity(0.15),
                      progressColor: color,
                      barRadius: const Radius.circular(4),
                      animation: true,
                      animationDuration: 800,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _formatDuration(int totalSeconds) {
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    if (mins > 0) {
      return '${mins}m ${secs}s';
    }
    return '${secs}s';
  }
}

// ---------------------------------------------------------------------------
// Stat Box Widget
// ---------------------------------------------------------------------------

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
