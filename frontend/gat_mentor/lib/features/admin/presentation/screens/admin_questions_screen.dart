import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/admin_provider.dart';

class AdminQuestionsScreen extends ConsumerStatefulWidget {
  const AdminQuestionsScreen({super.key});

  @override
  ConsumerState<AdminQuestionsScreen> createState() =>
      _AdminQuestionsScreenState();
}

class _AdminQuestionsScreenState extends ConsumerState<AdminQuestionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminQuestionsProvider.notifier).loadQuestions();
    });
  }

  Future<void> _confirmDeactivate(int questionId) async {
    final s = S.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deactivateQuestion),
        content: Text(s.deactivateWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(s.deactivate),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(adminQuestionsProvider.notifier).deactivateQuestion(questionId);
    }
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
        return 'Unknown';
    }
  }

  Color _difficultyColor(int d) {
    if (d <= 2) return AppColors.success;
    if (d == 3) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final state = ref.watch(adminQuestionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(s.questionManagement),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${state.total} total',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: state.isLoading && state.questions.isEmpty
          ? LoadingWidget(message: s.loadingQuestions)
          : state.error != null && state.questions.isEmpty
              ? ErrorDisplay(
                  message: state.error!,
                  onRetry: () => ref
                      .read(adminQuestionsProvider.notifier)
                      .loadQuestions(),
                )
              : Column(
                  children: [
                    // Question list
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => ref
                            .read(adminQuestionsProvider.notifier)
                            .loadQuestions(page: state.currentPage),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.questions.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, index) {
                            final q = state.questions[index];
                            return _QuestionCard(
                              question: q,
                              difficultyLabel: _difficultyLabel(
                                  q['difficulty'] as int? ?? 3),
                              difficultyColor: _difficultyColor(
                                  q['difficulty'] as int? ?? 3),
                              onDeactivate: () =>
                                  _confirmDeactivate(q['id'] as int),
                            );
                          },
                        ),
                      ),
                    ),

                    // Pagination bar
                    if (state.totalPages > 1) _buildPaginationBar(state),
                  ],
                ),
    );
  }

  Widget _buildPaginationBar(AdminQuestionsState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: state.currentPage > 1
                ? () => ref
                    .read(adminQuestionsProvider.notifier)
                    .previousPage()
                : null,
            icon: const Icon(Icons.chevron_left),
            color: AppColors.primary,
            disabledColor: AppColors.textHint,
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Page ${state.currentPage} of ${state.totalPages}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: state.currentPage < state.totalPages
                ? () =>
                    ref.read(adminQuestionsProvider.notifier).nextPage()
                : null,
            icon: const Icon(Icons.chevron_right),
            color: AppColors.primary,
            disabledColor: AppColors.textHint,
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// Question Card
// ==========================================================================

class _QuestionCard extends StatelessWidget {
  final Map<String, dynamic> question;
  final String difficultyLabel;
  final Color difficultyColor;
  final VoidCallback onDeactivate;

  const _QuestionCard({
    required this.question,
    required this.difficultyLabel,
    required this.difficultyColor,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final text = question['text'] as String? ?? 'No text';
    final isActive = question['is_active'] as bool? ?? true;
    final correctOption =
        (question['correct_option'] as String? ?? '').toUpperCase();
    final id = question['id'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? AppColors.surface : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? const Color(0xFFE2E8F0)
              : AppColors.textHint.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: ID + difficulty + status
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#$id',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: difficultyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  difficultyLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: difficultyColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Ans: $correctOption',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
              const Spacer(),
              if (!isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Inactive',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Question text preview
          Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: isActive
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          // Actions
          if (isActive)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onDeactivate,
                icon: const Icon(Icons.visibility_off_outlined, size: 16),
                label: Text(s.deactivate),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
