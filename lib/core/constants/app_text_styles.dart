import 'package:flutter/material.dart';
import 'app_colors.dart';

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

  static const TextStyle h4 = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
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

  // Label Styles (Semibold)
  static const TextStyle labelLarge = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle labelMedium = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle labelSmall = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 12,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
  );

  // Tab Label Styles
  static const TextStyle tabLabel = TextStyle(
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle tabLabelActive = TextStyle(
    color: AppColors.primary,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
  );

  // Card Styles
  static const TextStyle cardTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle cardSubtitle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle cardCaption = TextStyle(
    color: AppColors.iconSecondary,
    fontSize: 12,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
  );

  // Section Headers
  static const TextStyle sectionTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle sectionSubtitle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
  );

  // Status/Error Text
  static const TextStyle error = TextStyle(
    color: AppColors.error,
    fontSize: 14,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle success = TextStyle(
    color: AppColors.success,
    fontSize: 14,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle warning = TextStyle(
    color: AppColors.warning,
    fontSize: 14,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
  );

  // Action Text (for destructive actions, links)
  static const TextStyle actionDestructive = TextStyle(
    color: AppColors.error,
    fontSize: 14,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle actionPrimary = TextStyle(
    color: AppColors.primary,
    fontSize: 14,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
  );

  // Price/Amount Text
  static const TextStyle price = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle priceLarge = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 20,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
  );

  // Hint/Placeholder Text
  static const TextStyle hint = TextStyle(
    color: AppColors.hintText,
    fontSize: 14,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w400,
  );

  // Emoji/Icon Text (no font family for emoji support)
  static const TextStyle emoji = TextStyle(fontSize: 28);

  static const TextStyle emojiLarge = TextStyle(fontSize: 40);

  // Dialog Title
  static const TextStyle dialogTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontFamily: _fontFamily,
    fontWeight: FontWeight.w600,
  );
}
