import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary Colors
  static const Color primary = Color(0xFF009966);
  static const Color primaryLight = Color(0xFFD0FAE5);
  static const Color primaryDark = Color(0xFF007955);

  // Background Colors
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF101727);
  static const Color textSecondary = Color(0xFF697282);
  static const Color textTertiary = Color(0xFF495565);

  // Border Colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);

  // Status Colors - Success
  static const Color success = Color(0xFF009966);
  static const Color successLight = Color(0xFFD0FAE5);
  static const Color successDark = Color(0xFF007955);
  static const Color successBackground = Color(0xFFECFDF5);

  // Status Colors - Warning
  static const Color warning = Color(0xFFF44900);
  static const Color warningLight = Color(0xFFFFD6A7);
  static const Color warningDark = Color(0xFFC93400);
  static const Color warningBackground = Color(0xFFFFF7ED);
  static const Color warningText = Color(0xFF7E2A0B);

  // Status Colors - Error
  static const Color error = Color(0xFFE7000B);
  static const Color errorLight = Color(0xFFFB2C36);
  static const Color errorBackground = Color(0xFFFEE2E2);

  // Status Colors - Info (Blue)
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF1347E5);
  static const Color infoBackground = Color(0xFFEFF6FF);

  // Status Colors - Pending (Yellow/Amber)
  static const Color pending = Color(0xFFA65F00);
  static const Color pendingLight = Color(0xFFFEF9C2);

  // Action Colors
  static const Color actionPurple = Color(0xFF8200DA);
  static const Color actionPurpleLight = Color(0xFFE9D4FF);
  static const Color actionPurpleBackground = Color(0xFFFAF5FF);

  static const Color actionOrange = Color(0xFFC93400);
  static const Color actionOrangeLight = Color(0xFFFFD6A7);
  static const Color actionOrangeBackground = Color(0xFFFFF7ED);

  // Badge Colors
  static const Color badgeOrange = Color(0xFFFF6900);

  // Completed Status
  static const Color completed = Color(0xFF354152);
  static const Color completedBackground = Color(0xFFF3F4F6);
}
