import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';

class SnackbarHelper {
  static const Duration _defaultDuration = Duration(seconds: 4);

  static void showSuccess(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration? duration,
  }) {
    _show(
      context,
      message,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle_outline,
      action: action,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration? duration,
  }) {
    _show(
      context,
      message,
      backgroundColor: AppColors.error,
      icon: Icons.error_outline,
      action: action,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration? duration,
  }) {
    // Using a dark neutral or primary color for info often looks better than bright blue
    _show(
      context,
      message,
      backgroundColor: AppColors.textPrimary,
      icon: Icons.info_outline,
      action: action,
      duration: duration,
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required IconData icon,
    SnackBarAction? action,
    Duration? duration,
  }) {
    // Clear existing snackbars to avoid stacking
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: AppDimensions.iconS),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.body2.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        duration: duration ?? _defaultDuration,
        margin: const EdgeInsets.all(AppDimensions.paddingL),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingL,
          vertical: AppDimensions.paddingS,
        ),
        action: action,
      ),
    );
  }
}
