import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';

class SnackbarHelper {
  static const Duration _defaultDuration = Duration(seconds: 4);

  static void showSuccess(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration? duration,
  }) {
    _show(
      context,
      message,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle_outline,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration? duration,
  }) {
    _show(
      context,
      message,
      backgroundColor: AppColors.error,
      icon: Icons.error_outline,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration? duration,
  }) {
    // Using a dark neutral or primary color for info often looks better than bright blue
    _show(
      context,
      message,
      backgroundColor: AppColors.textPrimary,
      icon: Icons.info_outline,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      duration: duration,
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required IconData icon,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration? duration,
  }) {
    // Use removeCurrentSnackBar to immediately clear the current one
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: AppDimensions.iconS),
            const SizedBox(width: AppDimensions.spacingS),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.body2.copyWith(color: Colors.white),
              ),
            ),
            // Inline action button to avoid extra height from SnackBarAction
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(width: AppDimensions.spacingS),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onActionPressed();
                },
                child: Text(
                  actionLabel,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        duration: duration ?? _defaultDuration,
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingL,
          vertical: AppDimensions.paddingM,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingL,
          vertical: AppDimensions.paddingM,
        ),
      ),
    );
  }
}
