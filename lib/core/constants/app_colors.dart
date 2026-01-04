import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary Colors (Refreshing to a vibrant green)
  static const Color primary = Color(0xFF10B981); // Emerald 500
  static const Color primaryLight = Color(0xFFD1FAE5); // Emerald 100
  static const Color primaryDark = Color(0xFF065F46); // Emerald 800

  // Background Colors
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textTertiary = Color(0xFF6B7280);

  // Border Colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);

  // Status Colors - Success (Using unified green)
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF065F46);
  static const Color successBackground = Color(0xFFECFDF5);

  // Status Colors - Warning
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningLight = Color(0xFFFEF3C7); // Amber 100
  static const Color warningDark = Color(0xFF92400E); // Amber 800
  static const Color warningBackground = Color(0xFFFFFBEB);
  static const Color warningText = Color(0xFF92400E);

  // Status Colors - Error
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorLight = Color(0xFFFEE2E2); // Red 100
  static const Color errorBackground = Color(0xFFFEF2F2);

  // Status Colors - Info (Shifted to Teal for consistency)
  static const Color info = Color(0xFF0D9488); // Teal 600
  static const Color infoLight = Color(0xFFCCFBF1); // Teal 100
  static const Color infoDark = Color(0xFF115E59); // Teal 800
  static const Color infoBackground = Color(0xFFF0FDFA);

  // Status Colors - Pending (Standardizing)
  static const Color pending = Color(0xFFD97706);
  static const Color pendingLight = Color(0xFFFEF3C7);

  // Action Colors (Simplified)
  static const Color actionGreen = Color(0xFF059669);
  static const Color actionGreenLight = Color(0xFFD1FAE5);
  static const Color actionGreenBackground = Color(0xFFECFDF5);

  // Completed Status (Neutral)
  static const Color completed = Color(0xFF374151);
  static const Color completedBackground = Color(0xFFF3F4F6);

  // Gradient Colors (Onboarding - matching new primary)
  static const Color gradientStart = Color(0xFF10B981);
  static const Color gradientEnd = Color(0xFF059669);
  static const Color gradientLight = Color(0xFFD1FAE5);

  // Role Theme Colors (Refined)
  static const Color farmerPrimary = Color(0xFF065F46);
  static const Color farmerPrimaryLight = Color(0xFFD1FAE5);

  static const Color customerPrimary = Color(0xFF10B981);
  static const Color customerPrimaryLight = Color(0xFFD1FAE5);
  static const Color customerAccent = Color(0xFF059669);

  // Gray Variants
  static const Color iconDefault = Color(0xFF111827);
  static const Color iconSecondary = Color(0xFF6B7280);
  static const Color iconTertiary = Color(0xFF9CA3AF);
  static const Color hintText = Color(0xFF9CA3AF);

  // Status Border Colors
  static const Color successBorder = Color(0xFF6EE7B7);
  static const Color infoBorder = Color(0xFF5EEAD4);
  static const Color warningBorder = Color(0xFFFCD34D);

  // Card/Container Colors
  static const Color containerLight = Color(0xFFF3F4F6);
  static const Color infoContainer = Color(0xFFF0FDFA);
  static const Color infoContainerBorder = Color(0xFFCCFBF1);
}
