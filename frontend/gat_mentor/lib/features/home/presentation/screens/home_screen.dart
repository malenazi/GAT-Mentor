import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_display.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeProvider.notifier).loadAll();
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(homeProvider.notifier).loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);
    final textTheme = Theme.of(context).textTheme;

    if (state.isLoading && state.plan == null) {
      return const Scaffold(
        body: LoadingWidget(message: 'Loading your plan...'),
      );
    }

    if (state.error != null && state.plan == null) {
      return Scaffold(
        body: ErrorDisplay(
          message: state.error!,
          onRetry: () => ref.read(homeProvider.notifier).loadAll(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // ── App bar with greeting ───────────────────────────────
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: AppColors.surface,
              elevation: 0,
              toolbarHeight: 72,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(),
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _userName(state),
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              actions: [
                // Streak badge
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _StreakBadge(count: state.streakCount),
                ),
              ],
            ),

            // ── Progress summary ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _ProgressCard(state: state),
              ),
            ),

            // ── Today's plan header ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today\'s Plan',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${state.completedCount}/${state.totalCount} done',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Plan items list ─────────────────────────────────────
            if (state.planItems.isEmpty)
              const SliverToBoxAdapter(child: _EmptyPlan())
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.builder(
                  itemCount: state.planItems.length,
                  itemBuilder: (_, i) {
                    final item = state.planItems[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PlanItemCard(
                        item: item,
                        onComplete: () {
                          final id = item['id'] as int?;
                          if (id != null) {
                            ref.read(homeProvider.notifier).completePlanItem(id);
                          }
                        },
                        onTap: () => _navigateToPractice(context, item),
                      ),
                    );
                  },
                ),
              ),

            // ── Quick actions header ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  'Quick Actions',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),

            // ── Quick action buttons ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.quiz_outlined,
                        label: 'Practice',
                        color: AppColors.primary,
                        onTap: () => context.go('/practice'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.refresh_outlined,
                        label: 'Review',
                        color: AppColors.warning,
                        onTap: () => context.go('/review'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.timer_outlined,
                        label: 'Timed Set',
                        color: AppColors.secondary,
                        onTap: () => context.go('/simulation'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _userName(HomeState state) {
    final name = state.plan?['user_name'] as String? ??
        state.plan?['name'] as String? ??
        state.streak?['user_name'] as String?;
    if (name != null && name.isNotEmpty) return name;
    return 'Student';
  }

  void _navigateToPractice(BuildContext context, Map<String, dynamic> item) {
    final concept = item['concept'] as String? ?? item['topic'] as String?;
    final type = item['type'] as String?;

    final queryParams = <String, String>{};
    if (concept != null) queryParams['concept'] = concept;
    if (type != null) queryParams['type'] = type;

    context.go(
      Uri(path: '/practice', queryParameters: queryParams).toString(),
    );
  }
}

// ==========================================================================
// Streak badge
// ==========================================================================

class _StreakBadge extends StatelessWidget {
  final int count;
  const _StreakBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: count > 0
            ? AppColors.warning.withOpacity(0.1)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            size: 20,
            color: count > 0 ? AppColors.warning : AppColors.textHint,
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: count > 0 ? AppColors.warning : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// Progress card
// ==========================================================================

class _ProgressCard extends StatelessWidget {
  final HomeState state;
  const _ProgressCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final completed = state.completedCount;
    final total = state.totalCount;
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Progress',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '$completed/$total',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'tasks completed',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// Plan item card
// ==========================================================================

class _PlanItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onComplete;
  final VoidCallback onTap;

  const _PlanItemCard({
    required this.item,
    required this.onComplete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final type = (item['type'] as String?) ?? 'practice';
    final concept =
        item['concept'] as String? ?? item['topic'] as String? ?? 'Practice';
    final duration = item['duration_minutes'] as int? ??
        item['duration'] as int? ??
        10;
    final questionCount =
        item['question_count'] as int? ?? item['questions'] as int? ?? 5;
    final isCompleted = item['completed'] == true;

    final typeInfo = _typeInfo(type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isCompleted ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.correctBg.withOpacity(0.5)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted
                  ? AppColors.correct.withOpacity(0.3)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              // Type icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.correct.withOpacity(0.12)
                      : typeInfo.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCompleted ? Icons.check : typeInfo.icon,
                  color: isCompleted ? AppColors.correct : typeInfo.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      concept,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isCompleted
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _MetaChip(
                          icon: Icons.timer_outlined,
                          label: '$duration min',
                        ),
                        const SizedBox(width: 12),
                        _MetaChip(
                          icon: Icons.help_outline,
                          label: '$questionCount Qs',
                        ),
                        const SizedBox(width: 12),
                        _MetaChip(
                          icon: typeInfo.icon,
                          label: typeInfo.label,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Checkbox
              Transform.scale(
                scale: 1.1,
                child: Checkbox(
                  value: isCompleted,
                  onChanged: isCompleted ? null : (_) => onComplete(),
                  activeColor: AppColors.correct,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _TypeInfo _typeInfo(String type) {
    switch (type.toLowerCase()) {
      case 'warm_up':
      case 'warmup':
      case 'warm-up':
        return _TypeInfo(Icons.wb_sunny_outlined, 'Warm-up', AppColors.warning);
      case 'weak_topic':
      case 'weak_drill':
      case 'weak-topic':
        return _TypeInfo(
            Icons.gps_fixed_outlined, 'Weak Topic', AppColors.error);
      case 'timed_sprint':
      case 'timed':
      case 'sprint':
        return _TypeInfo(
            Icons.timer_outlined, 'Timed Sprint', AppColors.secondary);
      case 'mistake_review':
      case 'review':
        return _TypeInfo(
            Icons.refresh_outlined, 'Review', AppColors.info);
      default:
        return _TypeInfo(
            Icons.quiz_outlined, 'Practice', AppColors.primary);
    }
  }
}

class _TypeInfo {
  final IconData icon;
  final String label;
  final Color color;
  const _TypeInfo(this.icon, this.label, this.color);
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textHint),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ==========================================================================
// Empty plan state
// ==========================================================================

class _EmptyPlan extends StatelessWidget {
  const _EmptyPlan();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: AppColors.textHint.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No plan for today',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Start practicing to generate your\npersonalized study plan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// Quick action button
// ==========================================================================

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
