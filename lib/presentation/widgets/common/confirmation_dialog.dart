import 'package:flutter/material.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';

/// A premium-styled confirmation dialog for destructive actions.
///
/// Features a branded icon, clear messaging, and polished buttons.
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final bool isDestructive;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    this.cancelText = 'Cancel',
    required this.icon,
    this.iconColor = AppColors.error,
    this.iconBackgroundColor = const Color(0xFFFEE2E2),
    this.isDestructive = true,
    required this.onConfirm,
    this.onCancel,
  });

  /// Factory for cart clear confirmation
  factory ConfirmationDialog.clearCart({
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    required int itemCount,
  }) {
    return ConfirmationDialog(
      title: 'Clear Cart?',
      message: itemCount == 1
          ? 'You have 1 item in your cart. This action cannot be undone.'
          : 'You have $itemCount items in your cart. This action cannot be undone.',
      confirmText: 'Clear Cart',
      icon: Icons.remove_shopping_cart_outlined,
      iconColor: AppColors.error,
      iconBackgroundColor: AppColors.errorBackground,
      isDestructive: true,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  /// Factory for delete product confirmation
  factory ConfirmationDialog.deleteProduct({
    required String productName,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) {
    return ConfirmationDialog(
      title: 'Delete Product?',
      message:
          'Are you sure you want to delete "$productName"? This action cannot be undone.',
      confirmText: 'Delete',
      icon: Icons.delete_outline,
      iconColor: AppColors.error,
      iconBackgroundColor: AppColors.errorBackground,
      isDestructive: true,
      onConfirm: onConfirm,
      onCancel: onCancel,
    );
  }

  /// Shows this dialog
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    String cancelText = 'Cancel',
    required IconData icon,
    Color iconColor = AppColors.error,
    Color iconBackgroundColor = const Color(0xFFFEE2E2),
    bool isDestructive = true,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ConfirmationDialog(
          title: title,
          message: message,
          confirmText: confirmText,
          cancelText: cancelText,
          icon: icon,
          iconColor: iconColor,
          iconBackgroundColor: iconBackgroundColor,
          isDestructive: isDestructive,
          onConfirm: () => Navigator.of(context).pop(true),
          onCancel: () => Navigator.of(context).pop(false),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  /// Shows clear cart confirmation dialog
  static Future<bool?> showClearCart(
    BuildContext context, {
    required int itemCount,
  }) {
    return show(
      context,
      title: 'Clear Cart?',
      message: itemCount == 1
          ? 'You have 1 item in your cart. This action cannot be undone.'
          : 'You have $itemCount items in your cart. This action cannot be undone.',
      confirmText: 'Clear Cart',
      icon: Icons.remove_shopping_cart_outlined,
      iconColor: AppColors.error,
      iconBackgroundColor: AppColors.errorBackground,
      isDestructive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppDimensions.paddingXL),
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingXL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon container with gradient background
                _buildIconContainer(),
                const SizedBox(height: AppDimensions.spacingL),

                // Title
                Text(
                  title,
                  style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spacingM),

                // Message
                Text(
                  message,
                  style: AppTextStyles.body2Secondary.copyWith(height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spacingXL),

                // Buttons
                _buildButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: iconBackgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Decorative ring
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: iconColor.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
          ),
          // Icon
          Icon(icon, size: 32, color: iconColor),
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Column(
      children: [
        // Primary action button (destructive)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive
                  ? AppColors.error
                  : AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isDestructive ? Icons.delete_outline : Icons.check,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  confirmText,
                  style: AppTextStyles.button.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // Cancel button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: onCancel ?? () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
            ),
            child: Text(
              cancelText,
              style: AppTextStyles.button.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
