import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/review_repository.dart';
import '../providers/review_provider.dart';

// ============================================================================
// ReviewQueueScreen
// ============================================================================

class ReviewQueueScreen extends ConsumerStatefulWidget {
  const ReviewQueueScreen({super.key});

  @override
  ConsumerState<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends ConsumerState<ReviewQueueScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reviewProvider.notifier).loadQueue();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rs = ref.watch(reviewProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Review Queue',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            if (rs.count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${rs.count}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(reviewProvider.notifier).loadQueue(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: rs.isLoading && rs.items.isEmpty
          ? _buildLoading()
          : rs.error != null && rs.items.isEmpty
              ? _buildError(rs.error!)
              : rs.isEmpty
                  ? _buildEmpty()
                  : _buildList(rs),
    );
  }

  // ---- Loading state ------------------------------------------------------

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  // ---- Error state --------------------------------------------------------

  Widget _buildError(String message) {
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
              onPressed: () => ref.read(reviewProvider.notifier).loadQueue(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Empty state --------------------------------------------------------

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.correct.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 44,
                color: AppColors.correct.withOpacity(0.7),
              ),
            ),
            const Gap(20),
            const Text(
              'No reviews due!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Gap(8),
            const Text(
              'Keep practicing and any mistakes\nwill show up here for review.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1, 1),
              duration: 500.ms,
              curve: Curves.easeOutBack,
            ),
      ),
    );
  }

  // ---- Review item list ---------------------------------------------------

  Widget _buildList(ReviewState rs) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(reviewProvider.notifier).loadQueue(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: rs.items.length,
        itemBuilder: (context, index) {
          final item = rs.items[index];
          final isExpanded = rs.expandedIds.contains(item.attemptId);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ReviewCard(
              item: item,
              isExpanded: isExpanded,
              onTapHeader: () => ref
                  .read(reviewProvider.notifier)
                  .toggleExpanded(item.attemptId),
              onGotIt: () => ref
                  .read(reviewProvider.notifier)
                  .markGotIt(item.attemptId),
              onStillConfused: () => ref
                  .read(reviewProvider.notifier)
                  .markStillConfused(item.attemptId),
            )
                .animate()
                .fadeIn(
                  duration: 350.ms,
                  delay: Duration(milliseconds: 50 * index.clamp(0, 10)),
                )
                .slideY(
                  begin: 0.05,
                  end: 0,
                  duration: 350.ms,
                  delay: Duration(milliseconds: 50 * index.clamp(0, 10)),
                  curve: Curves.easeOut,
                ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// _ReviewCard -- an expandable card for a single review item
// ============================================================================

class _ReviewCard extends StatelessWidget {
  final ReviewItem item;
  final bool isExpanded;
  final VoidCallback onTapHeader;
  final VoidCallback onGotIt;
  final VoidCallback onStillConfused;

  const _ReviewCard({
    required this.item,
    required this.isExpanded,
    required this.onTapHeader,
    required this.onGotIt,
    required this.onStillConfused,
  });

  Color _mistakeBadgeColor(String? type) {
    switch (type) {
      case 'conceptual':
        return AppColors.error;
      case 'careless':
        return AppColors.warning;
      case 'time_pressure':
        return AppColors.info;
      case 'misread':
        return AppColors.secondary;
      case 'guessed':
        return AppColors.textHint;
      default:
        return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? AppColors.primary.withOpacity(0.3)
              : const Color(0xFFE2E8F0),
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Header (always visible)
          _buildHeader(),

          // Expandable body
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedBody(),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }

  // ---- Header -------------------------------------------------------------

  Widget _buildHeader() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTapHeader,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leading icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.wrong.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.replay_rounded,
                color: AppColors.wrong,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question snippet
                  Text(
                    item.questionSnippet,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Bottom row: concept, mistake badge, review count
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      // Concept chip
                      _smallChip(
                        item.conceptName,
                        AppColors.primary,
                      ),

                      // Mistake type badge
                      _smallChip(
                        item.mistakeTypeLabel,
                        _mistakeBadgeColor(item.mistakeType),
                      ),

                      // Review count
                      if (item.reviewCount > 0)
                        _smallChip(
                          'Reviewed ${item.reviewCount}x',
                          AppColors.textHint,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Expand/collapse chevron
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textHint,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // ---- Expanded body ------------------------------------------------------

  Widget _buildExpandedBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const Gap(14),

          // Full question text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              item.questionSnippet,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.55,
              ),
            ),
          ),
          const Gap(12),

          // Your answer vs correct answer
          Row(
            children: [
              Expanded(
                child: _answerBox(
                  label: 'Your Answer',
                  option: item.selectedOption,
                  color: AppColors.wrong,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _answerBox(
                  label: 'Correct',
                  option: item.correctOption,
                  color: AppColors.correct,
                ),
              ),
            ],
          ),

          // Explanation
          if (item.explanation != null && item.explanation!.isNotEmpty) ...[
            const Gap(12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Explanation',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.explanation!,
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

          // Why wrong
          if (item.whyWrong != null && item.whyWrong!.isNotEmpty) ...[
            const Gap(10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.wrong.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.wrong.withOpacity(0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why ${item.selectedOption} is wrong',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.wrong,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.whyWrong!,
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

          const Gap(16),

          // Action buttons: Got it / Still confused
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onStillConfused,
                  icon: const Icon(Icons.help_outline_rounded, size: 18),
                  label: const Text('Still Confused'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warning,
                    side: const BorderSide(color: AppColors.warning),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onGotIt,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Got It!'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.correct,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _answerBox({
    required String label,
    required String option,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              option,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
