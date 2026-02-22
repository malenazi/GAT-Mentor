import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/question_model.dart';
import '../../data/question_repository.dart';

// ---------------------------------------------------------------------------
// A FutureProvider that fetches the full question detail (with solution)
// for a given question ID.
// ---------------------------------------------------------------------------

final questionDetailProvider =
    FutureProvider.autoDispose.family<QuestionDetail, int>((ref, id) async {
  final repo = ref.read(questionRepositoryProvider);
  return repo.getQuestionDetail(id);
});

// ============================================================================
// SolutionScreen
// ============================================================================

class SolutionScreen extends ConsumerWidget {
  final int questionId;

  const SolutionScreen({super.key, required this.questionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(questionDetailProvider(questionId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Solution',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => _buildError(context, ref, error.toString()),
        data: (detail) => _buildSolution(context, detail),
      ),
    );
  }

  // ---- Error state --------------------------------------------------------

  Widget _buildError(BuildContext context, WidgetRef ref, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error.withOpacity(0.7)),
            const Gap(16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const Gap(20),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(questionDetailProvider(questionId)),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Solution content ---------------------------------------------------

  Widget _buildSolution(BuildContext context, QuestionDetail detail) {
    const options = ['A', 'B', 'C', 'D'];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question text
          _sectionLabel('Question'),
          const Gap(8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: SelectableText(
              detail.text,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.6,
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.04, end: 0, duration: 350.ms),

          const Gap(20),

          // Options with correct answer highlighted
          _sectionLabel('Answer'),
          const Gap(8),
          ...options.map((letter) {
            final isCorrect = letter == detail.correctOption;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isCorrect ? AppColors.correctBg : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCorrect
                        ? AppColors.correct.withOpacity(0.4)
                        : const Color(0xFFE2E8F0),
                    width: isCorrect ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? AppColors.correct
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        letter,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isCorrect
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        detail.optionText(letter),
                        style: TextStyle(
                          fontSize: 14,
                          color: isCorrect
                              ? const Color(0xFF065F46)
                              : AppColors.textPrimary,
                          fontWeight:
                              isCorrect ? FontWeight.w600 : FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (isCorrect)
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.correct, size: 22),
                  ],
                ),
              ),
            );
          }),

          const Gap(24),

          // Step-by-step explanation (Markdown)
          _sectionLabel('Step-by-Step Solution'),
          const Gap(8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: MarkdownBody(
              data: detail.explanation,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  height: 1.65,
                ),
                h1: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                h2: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                h3: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                strong: const TextStyle(fontWeight: FontWeight.w700),
                em: const TextStyle(fontStyle: FontStyle.italic),
                code: TextStyle(
                  fontSize: 14,
                  backgroundColor: AppColors.surfaceVariant,
                  color: AppColors.secondary,
                ),
                codeblockDecoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                blockquoteDecoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.04),
                  border: Border(
                    left: BorderSide(
                      color: AppColors.primary.withOpacity(0.4),
                      width: 3,
                    ),
                  ),
                ),
                listBullet: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .slideY(begin: 0.04, end: 0, duration: 400.ms, delay: 100.ms),

          const Gap(32),

          // Back to Practice button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              label: const Text(
                'Back to Practice',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Helpers ------------------------------------------------------------

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }
}
