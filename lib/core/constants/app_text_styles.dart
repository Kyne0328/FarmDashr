import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized text styles for the FarmDashr app.
/// Follows Single Responsibility Principle - only handles text style definitions.
class AppTextStyles {
  AppTextStyles._(); // Private constructor to prevent instantiation

  static const String _fontFamily = 'Arimo';

  // Headings
  static const TextStyle h1 = TextStyle(
    color: AppColors.primary,
    fontSize: 24,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle h2 = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    height: 1.50,
  );

  static const TextStyle h3 = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    height: 1.50,
  );

  // Body Text
  static const TextStyle body1 = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    height: 1.50,
  );

  static const TextStyle body2 = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    height: 1.43,
  );

  static const TextStyle body2Secondary = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    height: 1.43,
  );

  static const TextStyle body2Tertiary = TextStyle(
    color: AppColors.textTertiary,
    fontSize: 14,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    height: 1.43,
  );

  // Caption / Small Text
  static const TextStyle caption = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    height: 1.33,
  );

  static const TextStyle captionPrimary = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 12,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    height: 1.33,
  );

  // Button Text
  static const TextStyle button = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    height: 1.50,
  );

  static const TextStyle buttonSmall = TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    height: 1.43,
  );

  // Stat Value
  static const TextStyle statValue = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    height: 1.50,
  );

  static const TextStyle statLabel = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    height: 1.33,
  );

  static const TextStyle statChange = TextStyle(
    color: AppColors.success,
    fontSize: 12,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    height: 1.33,
  );

  // Navigation
  static const TextStyle navLabel = TextStyle(
    fontSize: 12,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
  );

  // Subtitle / Secondary text
  static const TextStyle subtitle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 16,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
  );

  // Link Text
  static const TextStyle link = TextStyle(
    color: AppColors.primary,
    fontSize: 14,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
    height: 1.43,
  );

  /// Helper to copy a style with a different color
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }
}
