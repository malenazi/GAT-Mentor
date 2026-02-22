import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/practice_provider.dart';
import '../widgets/option_tile.dart';

// ============================================================================
// PracticeScreen -- the core screen of the GAT Mentor app
// ============================================================================

class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen>
    with TickerProviderStateMixin {
  late AnimationController _submitPulseController;

  @override
  void initState() {
    super.initState();
    _submitPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Load the first question after the widget tree is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(practiceProvider.notifier).loadNextQuestion();
    });
  }

  @override
  void dispose() {
    _submitPulseController.dispose();
    super.dispose();
  }

  // ---- Helpers ------------------------------------------------------------

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _difficultyLabel(int d) {
    switch (d) {
      case 1:
        return 'Very Easy';
      case 2:
        return 'Easy';
      case 3:
        return 'Medium';
      case 4:
        return 'Hard';
      case 5:
        return 'Very Hard';
      default:
        return 'Medium';
    }
  }

  Color _difficultyColor(int d) {
    if (d <= 2) return AppColors.success;
    if (d == 3) return AppColors.warning;
    return AppColors.error;
  }

  OptionState _optionState(String letter, PracticeState ps) {
    if (!ps.isSubmitted) {
      return ps.selectedOption == letter
          ? OptionState.selected
          : OptionState.idle;
    }
    // Post-submission states (backend returns lowercase, UI uses uppercase)
    final correct = ps.attemptResult?.correctOption?.toUpperCase();
    if (letter == correct) return OptionState.correct;
    if (letter == ps.selectedOption) return OptionState.wrong;
    return OptionState.disabled;
  }

  // ---- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final ps = ref.watch(practiceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ps.isLoading && ps.question == null
            ? _buildLoadingState()
            : ps.error != null && ps.question == null
                ? _buildErrorState(ps.error!)
                : ps.question == null
                    ? _buildEmptyState()
                    : _buildQuestionView(ps),
      ),
    );
  }

  // ---- Loading / Error / Empty states -------------------------------------

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          const Gap(20),
          Text(
            'Finding your next question...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1200.ms, color: AppColors.primaryLight.withOpacity(0.3)),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 56, color: AppColors.error.withOpacity(0.7)),
            const Gap(16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const Gap(24),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(practiceProvider.notifier).loadNextQuestion(),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_rounded,
                size: 64, color: AppColors.primary.withOpacity(0.5)),
            const Gap(16),
            const Text(
              'Ready to practice!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Gap(8),
            const Text(
              'Tap the button below to get your first question.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const Gap(24),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(practiceProvider.notifier).loadNextQuestion(),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Practice'),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Main question view -------------------------------------------------

  Widget _buildQuestionView(PracticeState ps) {
    final q = ps.question!;
    const options = ['A', 'B', 'C', 'D'];

    return Column(
      children: [
        // --- Top bar -------------------------------------------------------
        _buildTopBar(ps),

        // --- Scrollable content --------------------------------------------
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Topic / Concept chip row
                _buildChipRow(q.topicName, q.conceptName),
                const Gap(16),

                // Question text card
                _buildQuestionCard(q.text)
                    .animate()
                    .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                    .slideY(
                        begin: 0.05,
                        end: 0,
                        duration: 400.ms,
                        curve: Curves.easeOut),
                const Gap(20),

                // Options
                ...List.generate(options.length, (i) {
                  final letter = options[i];
                  return Padding(
                    padding: EdgeInsets.only(bottom: i < 3 ? 12 : 0),
                    child: OptionTile(
                      letter: letter,
                      text: q.optionText(letter),
                      optionState: _optionState(letter, ps),
                      onTap: ps.isSubmitted
                          ? null
                          : () => ref
                              .read(practiceProvider.notifier)
                              .selectOption(letter),
                    )
                        .animate()
                        .fadeIn(
                          duration: 350.ms,
                          delay: Duration(milliseconds: 80 * i),
                          curve: Curves.easeOut,
                        )
                        .slideX(
                          begin: 0.06,
                          end: 0,
                          duration: 350.ms,
                          delay: Duration(milliseconds: 80 * i),
                          curve: Curves.easeOut,
                        ),
                  );
                }),

                // Hint card (if revealed)
                if (ps.hintRevealed && ps.hintText != null) ...[
                  const Gap(16),
                  _buildHintCard(ps.hintText!),
                ],

                // Post-submit feedback
                if (ps.showingFeedback) ...[
                  const Gap(20),
                  _buildFeedbackSection(ps),
                ],
              ],
            ),
          ),
        ),

        // --- Bottom action bar ---------------------------------------------
        _buildBottomBar(ps),
      ],
    );
  }

  // ---- Top bar ------------------------------------------------------------

  Widget _buildTopBar(PracticeState ps) {
    final q = ps.question!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ps.isSubmitted
                  ? AppColors.surfaceVariant
                  : AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color:
                      ps.isSubmitted ? AppColors.textHint : AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatTime(ps.timeElapsed),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: ps.isSubmitted
                        ? AppColors.textHint
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Difficulty stars
          _buildDifficultyStars(q.difficulty),
        ],
      ),
    );
  }

  Widget _buildDifficultyStars(int difficulty) {
    final color = _difficultyColor(difficulty);
    return Tooltip(
      message: _difficultyLabel(difficulty),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _difficultyLabel(difficulty),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          ...List.generate(5, (i) {
            return Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Icon(
                i < difficulty
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 18,
                color: i < difficulty ? color : color.withOpacity(0.3),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---- Chip row -----------------------------------------------------------

  Widget _buildChipRow(String topic, String concept) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        if (topic.isNotEmpty)
          _chip(topic, Icons.menu_book_rounded, AppColors.secondary),
        if (concept.isNotEmpty)
          _chip(concept, Icons.lightbulb_outline_rounded, AppColors.primary),
      ],
    );
  }

  Widget _chip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ---- Question card ------------------------------------------------------

  Widget _buildQuestionCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SelectableText(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          height: 1.6,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  // ---- Hint card ----------------------------------------------------------

  Widget _buildHintCard(String hint) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tips_and_updates_rounded,
              size: 20, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hint',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hint,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }

  // ---- Post-submit feedback section ---------------------------------------

  Widget _buildFeedbackSection(PracticeState ps) {
    final result = ps.attemptResult!;
    final isCorrect = result.isCorrect;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Correct / Wrong banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isCorrect ? AppColors.correctBg : AppColors.wrongBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCorrect
                  ? AppColors.correct.withOpacity(0.3)
                  : AppColors.wrong.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isCorrect
                    ? Icons.celebration_rounded
                    : Icons.close_rounded,
                color: isCorrect ? AppColors.correct : AppColors.wrong,
                size: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCorrect ? 'Correct!' : 'Not quite right',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isCorrect
                            ? const Color(0xFF065F46)
                            : const Color(0xFF991B1B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCorrect
                          ? 'Great job! The answer is ${result.correctOption.toUpperCase()}.'
                          : 'The correct answer is ${result.correctOption.toUpperCase()}.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isCorrect
                            ? const Color(0xFF065F46).withOpacity(0.8)
                            : const Color(0xFF991B1B).withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(
              begin: const Offset(0.95, 0.95),
              end: const Offset(1, 1),
              duration: 400.ms,
              curve: Curves.easeOutBack,
            ),

        const Gap(14),

        // Mastery change indicator
        _buildMasteryChange(result.masteryChange, result.newMastery),

        // "Why wrong" explanation (only for wrong answers)
        if (!isCorrect && result.whyWrong != null) ...[
          const Gap(14),
          _buildWhyWrongCard(result.whyWrong!, result.selectedOption),
        ],

        const Gap(14),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push(
                    '/practice/solution/${ps.question!.id}'),
                icon: const Icon(Icons.menu_book_rounded, size: 18),
                label: const Text('View Solution'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    ref.read(practiceProvider.notifier).resetForNext(),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Next Question'),
              ),
            ),
          ],
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 300.ms)
            .slideY(
              begin: 0.15,
              end: 0,
              duration: 400.ms,
              delay: 300.ms,
              curve: Curves.easeOut,
            ),
      ],
    );
  }

  Widget _buildMasteryChange(double change, double newMastery) {
    final isPositive = change >= 0;
    final color = isPositive ? AppColors.correct : AppColors.wrong;
    final sign = isPositive ? '+' : '';
    final masteryPercent = (newMastery * 100).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(
            isPositive
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            'Mastery: $sign${(change * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.getMasteryColor(newMastery).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$masteryPercent%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.getMasteryColor(newMastery),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 150.ms)
        .slideX(
          begin: -0.1,
          end: 0,
          duration: 400.ms,
          delay: 150.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildWhyWrongCard(String whyWrong, String selectedOption) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.wrong.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Why $selectedOption is wrong',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.wrong,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            whyWrong,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.55,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 200.ms)
        .slideY(
          begin: 0.1,
          end: 0,
          duration: 400.ms,
          delay: 200.ms,
          curve: Curves.easeOut,
        );
  }

  // ---- Bottom bar ---------------------------------------------------------

  Widget _buildBottomBar(PracticeState ps) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ps.isSubmitted
          ? const SizedBox.shrink()
          : Row(
              children: [
                // Hint button
                _buildHintButton(ps),
                const SizedBox(width: 10),

                // "I Guessed" toggle
                _buildGuessedToggle(ps),
                const SizedBox(width: 12),

                // Submit button
                Expanded(child: _buildSubmitButton(ps)),
              ],
            ),
    );
  }

  Widget _buildHintButton(PracticeState ps) {
    final revealed = ps.hintRevealed;
    return Material(
      color: revealed
          ? AppColors.warning.withOpacity(0.1)
          : AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: revealed
            ? null
            : () => ref.read(practiceProvider.notifier).revealHint(),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(
            revealed
                ? Icons.tips_and_updates_rounded
                : Icons.lightbulb_outline_rounded,
            size: 22,
            color: revealed ? AppColors.warning : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildGuessedToggle(PracticeState ps) {
    return GestureDetector(
      onTap: () => ref.read(practiceProvider.notifier).toggleGuessed(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: ps.wasGuessed
              ? AppColors.secondary.withOpacity(0.1)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ps.wasGuessed
                ? AppColors.secondary.withOpacity(0.4)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ps.wasGuessed
                  ? Icons.casino_rounded
                  : Icons.casino_outlined,
              size: 18,
              color: ps.wasGuessed
                  ? AppColors.secondary
                  : AppColors.textHint,
            ),
            const SizedBox(width: 6),
            Text(
              'Guess',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    ps.wasGuessed ? FontWeight.w700 : FontWeight.w500,
                color: ps.wasGuessed
                    ? AppColors.secondary
                    : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(PracticeState ps) {
    final canSubmit = ps.canSubmit;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      height: 48,
      child: ElevatedButton(
        onPressed:
            canSubmit
                ? () => ref.read(practiceProvider.notifier).submitAnswer()
                : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              canSubmit ? AppColors.primary : AppColors.surfaceVariant,
          foregroundColor:
              canSubmit ? Colors.white : AppColors.textHint,
          disabledBackgroundColor: AppColors.surfaceVariant,
          disabledForegroundColor: AppColors.textHint,
          elevation: canSubmit ? 2 : 0,
          shadowColor: AppColors.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: ps.isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_rounded, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Submit Answer',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
