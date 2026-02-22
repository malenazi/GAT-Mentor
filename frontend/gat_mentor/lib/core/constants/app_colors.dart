import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF1D4ED8);

  // Secondary
  static const Color secondary = Color(0xFF7C3AED);
  static const Color secondaryLight = Color(0xFFA78BFA);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Mastery levels
  static const Color masteryLow = Color(0xFFEF4444);
  static const Color masteryMedium = Color(0xFFF59E0B);
  static const Color masteryHigh = Color(0xFF10B981);
  static const Color masteryMaster = Color(0xFF7C3AED);

  // Backgrounds
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // Text
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);

  // Correct/Wrong
  static const Color correct = Color(0xFF10B981);
  static const Color correctBg = Color(0xFFD1FAE5);
  static const Color wrong = Color(0xFFEF4444);
  static const Color wrongBg = Color(0xFFFEE2E2);

  static Color getMasteryColor(double mastery) {
    if (mastery >= 0.8) return masteryMaster;
    if (mastery >= 0.6) return masteryHigh;
    if (mastery >= 0.3) return masteryMedium;
    return masteryLow;
  }
}
