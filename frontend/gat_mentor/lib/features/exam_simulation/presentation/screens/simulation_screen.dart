import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../providers/simulation_provider.dart';

class SimulationScreen extends ConsumerStatefulWidget {
  final int sessionId;

  const SimulationScreen({super.key, required this.sessionId});

  @override
  ConsumerState<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends ConsumerState<SimulationScreen> {
  @override
  void initState() {
    super.initState();
    final state = ref.read(simulationProvider);
    // If we navigated here directly (e.g. deep link) and session isn't loaded,
    // load it from the server.
    if (state.sessionId != widget.sessionId || state.questions.isEmpty) {
      Future.microtask(() {
        ref.read(simulationProvider.notifier).loadSession(widget.sessionId);
      });
    }
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmSubmit() async {
    final s = S.of(context);
    final unanswered =
        ref.read(simulationProvider).totalQuestions -
            ref.read(simulationProvider).answers.length;

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) {
        final s = S.of(context);
        return AlertDialog(
          title: Text(s.submitExam),
          content: Text(
            unanswered > 0
                ? '${s.unansweredWarning(unanswered)}. '
                    '${s.sureSubmit}'
                : s.sureSubmitExam,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(s.submit),
            ),
          ],
        );
      },
    );

    if (shouldSubmit == true) {
      await ref.read(simulationProvider.notifier).submitAll();
      final state = ref.read(simulationProvider);
      if (state.isComplete && mounted) {
        context.go('/simulation/result/${widget.sessionId}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final state = ref.watch(simulationProvider);

    if (state.isLoading && state.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(s.simulation)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null && state.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(s.simulation)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(state.error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/simulation'),
                  child: Text(s.goBack),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = state.currentQuestion;
    if (question == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.simulation)),
        body: Center(child: Text(s.noQuestionsAvailable)),
      );
    }

    final questionId = question['id'] as int;
    final questionText = question['text'] as String? ?? '';
    final options = [
      question['option_a'] as String? ?? '',
      question['option_b'] as String? ?? '',
      question['option_c'] as String? ?? '',
      question['option_d'] as String? ?? '',
    ];
    final selectedIndex = state.answers[questionId];
    final isTimeLow = state.timeRemaining < 60;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _showExitDialog();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Top bar: progress + timer
              _buildTopBar(state, isTimeLow),

              // Question content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question number
                      Text(
                        s.questionOf(state.currentIndex + 1, state.totalQuestions),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Question text
                      Text(
                        questionText,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Options
                      ...List.generate(options.length, (index) {
                        final isSelected = selectedIndex == index;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              ref
                                  .read(simulationProvider.notifier)
                                  .answerQuestion(questionId, index);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withOpacity(0.08)
                                    : AppColors.surface,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : const Color(0xFFE2E8F0),
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.surfaceVariant,
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(65 + index),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      options[index],
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Bottom navigation
              _buildBottomBar(state),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top bar
  // ---------------------------------------------------------------------------

  Widget _buildTopBar(SimulationState state, bool isTimeLow) {
    final progress = state.totalQuestions > 0
        ? (state.currentIndex + 1) / state.totalQuestions
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Question counter
              Text(
                '${state.currentIndex + 1}/${state.totalQuestions}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              // Timer
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isTimeLow
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: isTimeLow
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(state.timeRemaining),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isTimeLow
                            ? AppColors.error
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppColors.surfaceVariant,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom bar
  // ---------------------------------------------------------------------------

  Widget _buildBottomBar(SimulationState state) {
    final s = S.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          // Previous button
          if (state.currentIndex > 0)
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(simulationProvider.notifier).previousQuestion(),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(s.prev),
            )
          else
            const SizedBox(width: 100),

          const Spacer(),

          // Next or Submit button
          if (state.isLastQuestion)
            ElevatedButton.icon(
              onPressed: state.isLoading ? null : _confirmSubmit,
              icon: state.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline, size: 18),
              label: Text(state.isLoading ? s.submitting : s.submitAll),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(simulationProvider.notifier).nextQuestion(),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: Text(s.next),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Exit dialog
  // ---------------------------------------------------------------------------

  Future<void> _showExitDialog() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) {
        final s = S.of(context);
        return AlertDialog(
          title: Text(s.leaveSimulation),
          content: Text(s.simulationLeaveWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.stay),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error),
              child: Text(s.leave),
            ),
          ],
        );
      },
    );

    if (shouldExit == true && mounted) {
      ref.read(simulationProvider.notifier).reset();
      context.go('/simulation');
    }
  }
}
