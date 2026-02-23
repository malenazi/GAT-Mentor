import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_display.dart';
import '../providers/onboarding_provider.dart';

class DiagnosticTestScreen extends ConsumerStatefulWidget {
  const DiagnosticTestScreen({super.key});

  @override
  ConsumerState<DiagnosticTestScreen> createState() =>
      _DiagnosticTestScreenState();
}

class _DiagnosticTestScreenState extends ConsumerState<DiagnosticTestScreen> {
  int _currentIndex = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Load questions if not already loaded.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final questions = ref.read(onboardingProvider).diagnosticQuestions;
      if (questions.isEmpty) {
        ref.read(onboardingProvider.notifier).loadDiagnostic();
      }
    });
  }

  int get _totalQuestions {
    final questions = ref.read(onboardingProvider).diagnosticQuestions;
    return questions.isEmpty ? 15 : questions.length;
  }

  void _selectOption(int choiceIndex) {
    ref.read(onboardingProvider.notifier).selectAnswer(_currentIndex, choiceIndex);
    // Auto-advance after a short delay so the user sees their selection.
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      if (_currentIndex < _totalQuestions - 1) {
        setState(() => _currentIndex++);
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final success =
        await ref.read(onboardingProvider.notifier).submitDiagnostic();
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (success) {
      context.go('/onboarding/result');
    } else {
      final s = S.of(context);
      final error = ref.read(onboardingProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? s.submissionFailed),
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

    if (state.isLoading && state.diagnosticQuestions.isEmpty) {
      return Scaffold(
        body: LoadingWidget(message: s.loadingDiagnostic),
      );
    }

    if (state.error != null && state.diagnosticQuestions.isEmpty) {
      return Scaffold(
        body: ErrorDisplay(
          message: state.error!,
          onRetry: () =>
              ref.read(onboardingProvider.notifier).loadDiagnostic(),
        ),
      );
    }

    final questions = state.diagnosticQuestions;
    if (questions.isEmpty) {
      return Scaffold(
        body: LoadingWidget(message: s.preparingQuestions),
      );
    }

    final question = questions[_currentIndex];
    final questionText = question['text'] as String? ??
        question['question'] as String? ??
        '';
    final options = _extractOptions(question);
    final selectedOption = state.selectedAnswers[_currentIndex];
    final progress = (_currentIndex + 1) / questions.length;
    final isLastQuestion = _currentIndex == questions.length - 1;
    final allAnswered = state.selectedAnswers.length == questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(s.diagnosticAssessment),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(context),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_currentIndex + 1}/${questions.length}',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress bar ────────────────────────────────────────
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceVariant,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 4,
            ),

            // ── Question body ───────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Concept tag
                    if (question['concept_name'] != null ||
                        question['concept'] != null ||
                        question['topic'] != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (question['concept_name'] ?? question['concept'] ?? question['topic'])
                              as String,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),

                    // Question text
                    Text(
                      questionText,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Answer options
                    ...List.generate(options.length, (i) {
                      final isSelected = selectedOption == i;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _OptionButton(
                          label: String.fromCharCode(65 + i), // A, B, C, D
                          text: options[i],
                          isSelected: isSelected,
                          onTap: () => _selectOption(i),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // ── Navigation row ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                children: [
                  // Previous button
                  if (_currentIndex > 0)
                    OutlinedButton.icon(
                      onPressed: () =>
                          setState(() => _currentIndex--),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: Text(s.back),
                    )
                  else
                    const SizedBox.shrink(),

                  const Spacer(),

                  // Next / Submit button
                  if (isLastQuestion && allAnswered)
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(s.submit),
                    )
                  else if (!isLastQuestion && selectedOption != null)
                    ElevatedButton.icon(
                      onPressed: () =>
                          setState(() => _currentIndex++),
                      icon: Text(s.next),
                      label: const Icon(Icons.arrow_forward, size: 18),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Extracts a list of option strings from various possible API shapes.
  List<String> _extractOptions(Map<String, dynamic> question) {
    // Shape 1: { "options": ["A", "B", "C", "D"] }
    if (question['options'] is List) {
      return (question['options'] as List).map((e) => e.toString()).toList();
    }
    // Shape 2: { "option_a": "...", "option_b": "...", ... }
    final keys = ['option_a', 'option_b', 'option_c', 'option_d'];
    final mapped = keys
        .where((k) => question[k] != null)
        .map((k) => question[k].toString())
        .toList();
    if (mapped.isNotEmpty) return mapped;
    // Fallback
    return ['Option A', 'Option B', 'Option C', 'Option D'];
  }

  void _showExitDialog(BuildContext context) {
    final s = S.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.leaveDiagnostic),
        content: Text(s.diagnosticLeaveWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/onboarding');
            },
            child: Text(
              s.leave,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// Option button widget
// ==========================================================================

class _OptionButton extends StatelessWidget {
  final String label;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionButton({
    required this.label,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isSelected ? AppColors.primary.withOpacity(0.06) : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color:
                        isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
