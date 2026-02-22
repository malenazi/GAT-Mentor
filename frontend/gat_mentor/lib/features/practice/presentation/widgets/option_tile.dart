import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';

// ---------------------------------------------------------------------------
// Option visual state
// ---------------------------------------------------------------------------

enum OptionState {
  /// Not selected, not submitted.
  idle,

  /// Selected by the student (before submission).
  selected,

  /// This is the correct answer (after submission).
  correct,

  /// This was chosen and is wrong (after submission).
  wrong,

  /// This was NOT chosen and NOT correct -- just a neutral post-submit state.
  disabled,
}

// ---------------------------------------------------------------------------
// OptionTile widget
// ---------------------------------------------------------------------------

/// A single selectable answer option (A/B/C/D) with animated transitions
/// between visual states. Designed to feel satisfying to tap.
class OptionTile extends StatelessWidget {
  final String letter; // 'A', 'B', 'C', 'D'
  final String text;
  final OptionState optionState;
  final VoidCallback? onTap;

  const OptionTile({
    super.key,
    required this.letter,
    required this.text,
    required this.optionState,
    this.onTap,
  });

  // ---- Colours & styling per state ----------------------------------------

  Color get _backgroundColor {
    switch (optionState) {
      case OptionState.idle:
        return Colors.white;
      case OptionState.selected:
        return AppColors.primary.withOpacity(0.06);
      case OptionState.correct:
        return AppColors.correctBg;
      case OptionState.wrong:
        return AppColors.wrongBg;
      case OptionState.disabled:
        return AppColors.surfaceVariant.withOpacity(0.5);
    }
  }

  Color get _borderColor {
    switch (optionState) {
      case OptionState.idle:
        return const Color(0xFFE2E8F0);
      case OptionState.selected:
        return AppColors.primary;
      case OptionState.correct:
        return AppColors.correct;
      case OptionState.wrong:
        return AppColors.wrong;
      case OptionState.disabled:
        return const Color(0xFFE2E8F0).withOpacity(0.5);
    }
  }

  double get _borderWidth {
    switch (optionState) {
      case OptionState.idle:
        return 1.5;
      case OptionState.selected:
      case OptionState.correct:
      case OptionState.wrong:
        return 2.0;
      case OptionState.disabled:
        return 1.0;
    }
  }

  Color get _letterBgColor {
    switch (optionState) {
      case OptionState.idle:
        return AppColors.surfaceVariant;
      case OptionState.selected:
        return AppColors.primary;
      case OptionState.correct:
        return AppColors.correct;
      case OptionState.wrong:
        return AppColors.wrong;
      case OptionState.disabled:
        return AppColors.surfaceVariant.withOpacity(0.5);
    }
  }

  Color get _letterTextColor {
    switch (optionState) {
      case OptionState.idle:
        return AppColors.textSecondary;
      case OptionState.selected:
      case OptionState.correct:
      case OptionState.wrong:
        return Colors.white;
      case OptionState.disabled:
        return AppColors.textHint;
    }
  }

  Color get _textColor {
    switch (optionState) {
      case OptionState.idle:
        return AppColors.textPrimary;
      case OptionState.selected:
        return AppColors.primary;
      case OptionState.correct:
        return const Color(0xFF065F46); // darker green for readability
      case OptionState.wrong:
        return const Color(0xFF991B1B); // darker red for readability
      case OptionState.disabled:
        return AppColors.textHint;
    }
  }

  IconData? get _trailingIcon {
    switch (optionState) {
      case OptionState.correct:
        return Icons.check_circle_rounded;
      case OptionState.wrong:
        return Icons.cancel_rounded;
      default:
        return null;
    }
  }

  Color? get _trailingIconColor {
    switch (optionState) {
      case OptionState.correct:
        return AppColors.correct;
      case OptionState.wrong:
        return AppColors.wrong;
      default:
        return null;
    }
  }

  // ---- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bool isTappable =
        optionState == OptionState.idle || optionState == OptionState.selected;

    return GestureDetector(
      onTap: isTappable
          ? () {
              // Provide haptic feedback for a satisfying tap
              HapticFeedback.lightImpact();
              onTap?.call();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderColor, width: _borderWidth),
          boxShadow: optionState == OptionState.selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : optionState == OptionState.correct
                  ? [
                      BoxShadow(
                        color: AppColors.correct.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : optionState == OptionState.wrong
                      ? [
                          BoxShadow(
                            color: AppColors.wrong.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Letter badge
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _letterBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: _letterTextColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                child: Text(letter),
              ),
            ),
            const SizedBox(width: 14),

            // Option text
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 15,
                    fontWeight: optionState == OptionState.selected ||
                            optionState == OptionState.correct
                        ? FontWeight.w600
                        : FontWeight.w400,
                    height: 1.4,
                  ),
                  child: Text(text),
                ),
              ),
            ),

            // Trailing icon for correct/wrong
            if (_trailingIcon != null) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  _trailingIcon,
                  color: _trailingIconColor,
                  size: 24,
                )
                    .animate()
                    .scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: 400.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 200.ms),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
