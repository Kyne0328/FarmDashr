import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary Colors (Original Brand Green)
  static const Color primary = Color(0xFF009966);
  static const Color primaryLight = Color(0xFFD0FAE5);
  static const Color primaryDark = Color(0xFF007955);

  // Background Colors
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF101727);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textTertiary = Color(0xFF697282);

  // Border Colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);

  // Status Colors - Success (Green)
  static const Color success = Color(0xFF009966);
  static const Color successLight = Color(0xFFD0FAE5);
  static const Color successDark = Color(0xFF007955);
  static const Color successBackground = Color(0xFFECFDF5);

  // Status Colors - Warning (Amber/Orange)
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningLight = Color(0xFFFEF3C7); // Amber 100
  static const Color warningDark = Color(0xFF92400E); // Amber 800
  static const Color warningBackground = Color(0xFFFFFBEB);
  static const Color warningText = Color(0xFF92400E);

  // Status Colors - Error (Red)
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorBackground = Color(0xFFFEF2F2);

  // Status Colors - Info (Blue - Original)
  static const Color info = Color(0xFF3B82F6); // Blue 500
  static const Color infoLight = Color(0xFFDBEAFE); // Blue 100
  static const Color infoDark = Color(0xFF1E40AF); // Blue 800
  static const Color infoBackground = Color(0xFFEFF6FF);

  // Status Colors - Pending
  static const Color pending = Color(0xFFD97706);
  static const Color pendingLight = Color(0xFFFEF3C7);

  // Action Colors (Original - Purple and Orange)
  static const Color actionPurple = Color(0xFF7C3AED);
  static const Color actionPurpleLight = Color(0xFFEDE9FE);
  static const Color actionPurpleBackground = Color(0xFFF5F3FF);

  static const Color actionOrange = Color(0xFFC93400);
  static const Color actionOrangeLight = Color(0xFFFFD6A7);
  static const Color actionOrangeBackground = Color(0xFFFFF7ED);

  // Badge Colors (Original)
  static const Color badgeOrange = Color(0xFFFF6900);

  // Completed Status (Neutral Gray)
  static const Color completed = Color(0xFF354152);
  static const Color completedBackground = Color(0xFFF3F4F6);

  // Gradient Colors (Onboarding)
  static const Color gradientStart = Color(0xFF00BC7C);
  static const Color gradientEnd = Color(0xFF009865);
  static const Color gradientLight = Color(0xFFD0FAE4);

  // Role Theme Colors (Both Green)
  static const Color farmerPrimary = Color(0xFF166534); // Dark Green
  static const Color farmerPrimaryLight = Color(0xFFDCFCE7);

  static const Color customerPrimary = Color(0xFF009966); // Primary Green
  static const Color customerPrimaryLight = Color(0xFFD0FAE5);
  static const Color customerAccent = Color(0xFF007955);

  // Gray Variants
  static const Color iconDefault = Color(0xFF101727);
  static const Color iconSecondary = Color(0xFF6B7280);
  static const Color iconTertiary = Color(0xFF9CA3AF);
  static const Color hintText = Color(0xFF6B7280);

  // Status Border Colors
  static const Color successBorder = Color(0xFFA4F3CF);
  static const Color infoBorder = Color(0xFFBDDAFF);
  static const Color warningBorder = Color(0xFFFFEDD4);

  // Card/Container Colors
  static const Color containerLight = Color(0xFFF3F4F6);
  static const Color infoContainer = Color(0xFFEBF2FF);
  static const Color infoContainerBorder = Color(0xFFD0E1FF);
}
