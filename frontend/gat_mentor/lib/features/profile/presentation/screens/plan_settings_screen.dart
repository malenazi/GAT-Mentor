import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/profile_provider.dart';

class PlanSettingsScreen extends ConsumerStatefulWidget {
  const PlanSettingsScreen({super.key});

  @override
  ConsumerState<PlanSettingsScreen> createState() => _PlanSettingsScreenState();
}

class _PlanSettingsScreenState extends ConsumerState<PlanSettingsScreen> {
  DateTime? _examDate;
  double _dailyMinutes = 45;
  double _targetScore = 70;
  String _selectedLevel = 'average';
  bool _initialized = false;

  final List<String> _levels = const [
    'beginner',
    'average',
    'intermediate',
    'advanced',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initFromProfile();
    }
  }

  void _initFromProfile() {
    final state = ref.read(profileProvider);
    final user = state.user;
    if (user != null) {
      setState(() {
        _dailyMinutes = user.dailyMinutes.toDouble().clamp(15, 120);
        _targetScore = user.targetScore.toDouble().clamp(0, 100);
        _selectedLevel = user.level;
        if (user.examDate != null && user.examDate!.isNotEmpty) {
          _examDate = DateTime.tryParse(user.examDate!);
        }
        _initialized = true;
      });
    }
  }

  Future<void> _pickExamDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _examDate = picked);
    }
  }

  Future<void> _save() async {
    final examDateStr = _examDate != null
        ? '${_examDate!.year}-${_examDate!.month.toString().padLeft(2, '0')}-${_examDate!.day.toString().padLeft(2, '0')}'
        : null;

    await ref.read(profileProvider.notifier).updatePlanSettings(
          examDate: examDateStr,
          dailyMinutes: _dailyMinutes.round(),
          targetScore: _targetScore.round(),
          level: _selectedLevel,
        );

    final state = ref.read(profileProvider);
    if (state.successMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.successMessage!),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else if (state.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _capitalizeLevel(String level) {
    if (level.isEmpty) return level;
    return level[0].toUpperCase() + level.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Plan Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exam Date
            const Text(
              'Exam Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'When is your GAT exam?',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickExamDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 20, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      _examDate != null
                          ? '${_examDate!.day}/${_examDate!.month}/${_examDate!.year}'
                          : 'Select exam date',
                      style: TextStyle(
                        fontSize: 15,
                        color: _examDate != null
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textHint),
                  ],
                ),
              ),
            ),

            if (_examDate != null) ...[
              const SizedBox(height: 8),
              _buildDaysUntilExam(),
            ],

            const SizedBox(height: 28),

            // Daily Minutes Slider
            const Text(
              'Daily Study Time',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'How many minutes do you want to study each day?',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          '${_dailyMinutes.round()} minutes',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _dailyMinutes,
                      min: 15,
                      max: 120,
                      divisions: 21,
                      activeColor: AppColors.primary,
                      label: '${_dailyMinutes.round()} min',
                      onChanged: (value) {
                        setState(() => _dailyMinutes = value);
                      },
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('15 min',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint)),
                        Text('120 min',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Target Score Slider
            const Text(
              'Target Score',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'What score are you aiming for?',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.flag_outlined,
                            size: 20, color: AppColors.success),
                        const SizedBox(width: 8),
                        Text(
                          '${_targetScore.round()}%',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _targetScore,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      activeColor: AppColors.success,
                      label: '${_targetScore.round()}%',
                      onChanged: (value) {
                        setState(() => _targetScore = value);
                      },
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0%',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint)),
                        Text('100%',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Level Selector
            const Text(
              'Current Level',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'How would you describe your current ability?',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: _levels.map((level) {
                    final isSelected = _selectedLevel == level;
                    return RadioListTile<String>(
                      title: Text(
                        _capitalizeLevel(level),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      value: level,
                      groupValue: _selectedLevel,
                      activeColor: AppColors.primary,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedLevel = value);
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: state.isLoading ? null : _save,
                icon: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(state.isLoading ? 'Saving...' : 'Save Settings'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Days until exam
  // ---------------------------------------------------------------------------

  Widget _buildDaysUntilExam() {
    final daysLeft = _examDate!.difference(DateTime.now()).inDays;
    final color = daysLeft < 14
        ? AppColors.error
        : daysLeft < 30
            ? AppColors.warning
            : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            daysLeft > 0
                ? '$daysLeft days until your exam'
                : 'Exam date has passed',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
