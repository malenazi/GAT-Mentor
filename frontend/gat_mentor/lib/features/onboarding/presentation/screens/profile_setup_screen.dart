import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../providers/onboarding_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  static const _totalPages = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitProfile() async {
    final notifier = ref.read(onboardingProvider.notifier);
    final success = await notifier.setProfile();
    if (!mounted) return;
    if (success) {
      await notifier.loadDiagnostic();
      if (!mounted) return;
      context.go('/onboarding/diagnostic');
    } else {
      final error = ref.read(onboardingProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to save profile'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final state = ref.watch(onboardingProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(s.setupProfile),
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousPage,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress indicator ──────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: List.generate(_totalPages, (i) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: i <= _currentPage
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ── Pages ───────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _currentPage = p),
                children: [
                  _StudyFocusPage(
                    textTheme: textTheme,
                    selected: state.studyFocus,
                    onChanged: (v) =>
                        ref.read(onboardingProvider.notifier).setStudyFocus(v),
                  ),
                  _LevelPage(
                    textTheme: textTheme,
                    selected: state.level,
                    onChanged: (v) =>
                        ref.read(onboardingProvider.notifier).setLevel(v),
                  ),
                  _ExamDatePage(
                    textTheme: textTheme,
                    selectedDate: state.examDate,
                    onChanged: (d) =>
                        ref.read(onboardingProvider.notifier).setExamDate(d),
                  ),
                  _GoalsPage(
                    textTheme: textTheme,
                    dailyMinutes: state.dailyMinutes,
                    targetScore: state.targetScore,
                    onMinutesChanged: (v) =>
                        ref.read(onboardingProvider.notifier).setDailyMinutes(v),
                    onScoreChanged: (v) =>
                        ref.read(onboardingProvider.notifier).setTargetScore(v),
                  ),
                ],
              ),
            ),

            // ── Bottom button ───────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : (_currentPage < _totalPages - 1
                          ? _nextPage
                          : _submitProfile),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _currentPage < _totalPages - 1
                              ? s.continueText
                              : s.startDiagnostic,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// Page 1 – Study Focus
// ==========================================================================

class _StudyFocusPage extends StatelessWidget {
  final TextTheme textTheme;
  final String selected;
  final ValueChanged<String> onChanged;

  const _StudyFocusPage({
    required this.textTheme,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            s.whatFocus,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.chooseFocusArea,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          _FocusCard(
            icon: Icons.calculate_outlined,
            label: s.quantitative,
            description: s.quantDesc,
            value: 'quant',
            selected: selected,
            onTap: onChanged,
          ),
          const SizedBox(height: 12),
          _FocusCard(
            icon: Icons.menu_book_outlined,
            label: s.verbal,
            description: s.verbalDesc,
            value: 'verbal',
            selected: selected,
            onTap: onChanged,
          ),
          const SizedBox(height: 12),
          _FocusCard(
            icon: Icons.auto_awesome_outlined,
            label: s.both,
            description: s.bothDesc,
            value: 'both',
            selected: selected,
            onTap: onChanged,
          ),
        ],
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;

  const _FocusCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.06)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.12)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================================
// Page 2 – Level
// ==========================================================================

class _LevelPage extends StatelessWidget {
  final TextTheme textTheme;
  final String selected;
  final ValueChanged<String> onChanged;

  const _LevelPage({
    required this.textTheme,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            s.describeLevel,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.personalizeStart,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          _LevelCard(
            icon: Icons.trending_up,
            label: s.beginner,
            description: s.beginnerDesc,
            value: 'beginner',
            color: AppColors.info,
            selected: selected,
            onTap: onChanged,
          ),
          const SizedBox(height: 12),
          _LevelCard(
            icon: Icons.speed,
            label: s.average,
            description: s.averageDesc,
            value: 'average',
            color: AppColors.warning,
            selected: selected,
            onTap: onChanged,
          ),
          const SizedBox(height: 12),
          _LevelCard(
            icon: Icons.star_outline,
            label: s.highScorer,
            description: s.highScorerDesc,
            value: 'high_scorer',
            color: AppColors.success,
            selected: selected,
            onTap: onChanged,
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final String value;
  final Color color;
  final String selected;
  final ValueChanged<String> onTap;

  const _LevelCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.06) : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.12)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? color : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected) Icon(Icons.check_circle, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================================
// Page 3 – Exam Date
// ==========================================================================

class _ExamDatePage extends StatelessWidget {
  final TextTheme textTheme;
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onChanged;

  const _ExamDatePage({
    required this.textTheme,
    required this.selectedDate,
    required this.onChanged,
  });

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) onChanged(picked);
  }

  String _formatDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }

  String _daysUntil(DateTime d) {
    final diff = d.difference(DateTime.now()).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return '1 day away';
    return '$diff days away';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            s.whenExam,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.studyPlanDeadline,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: () => _pickDate(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selectedDate != null
                      ? AppColors.primary
                      : const Color(0xFFE2E8F0),
                  width: selectedDate != null ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 48,
                    color: selectedDate != null
                        ? AppColors.primary
                        : AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    selectedDate != null
                        ? _formatDate(selectedDate!)
                        : s.tapSelectDate,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: selectedDate != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                  if (selectedDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _daysUntil(selectedDate!),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => onChanged(null),
              child: Text(
                s.noDateYet,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  decoration: selectedDate == null
                      ? TextDecoration.underline
                      : TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// Page 4 – Goals (daily study time & target score)
// ==========================================================================

class _GoalsPage extends StatelessWidget {
  final TextTheme textTheme;
  final int dailyMinutes;
  final int targetScore;
  final ValueChanged<int> onMinutesChanged;
  final ValueChanged<int> onScoreChanged;

  const _GoalsPage({
    required this.textTheme,
    required this.dailyMinutes,
    required this.targetScore,
    required this.onMinutesChanged,
    required this.onScoreChanged,
  });

  String _formatMinutes(int m) {
    if (m < 60) return '$m min';
    final h = m ~/ 60;
    final r = m % 60;
    return r == 0 ? '${h}h' : '${h}h ${r}m';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            s.setStudyGoals,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.changeInSettings,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          // ── Daily study time ───────────────────────────────────────
          const SizedBox(height: 36),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.timer_outlined,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      s.dailyStudyTime,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    _formatMinutes(dailyMinutes),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.surfaceVariant,
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withOpacity(0.12),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: dailyMinutes.toDouble(),
                    min: 15,
                    max: 120,
                    divisions: 7,
                    label: _formatMinutes(dailyMinutes),
                    onChanged: (v) => onMinutesChanged(v.round()),
                  ),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('15 min',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textHint)),
                    Text('2 hours',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textHint)),
                  ],
                ),
              ],
            ),
          ),

          // ── Target score ───────────────────────────────────────────
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.emoji_events_outlined,
                          color: AppColors.secondary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      s.targetScore,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    '$targetScore',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.secondary,
                    inactiveTrackColor: AppColors.surfaceVariant,
                    thumbColor: AppColors.secondary,
                    overlayColor: AppColors.secondary.withOpacity(0.12),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: targetScore.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '$targetScore',
                    onChanged: (v) => onScoreChanged(v.round()),
                  ),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textHint)),
                    Text('100',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textHint)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
