import 'package:flutter/material.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';

import 'package:farmdashr/core/services/haptic_service.dart';

enum FarmButtonStyle { primary, secondary, outline, ghost, danger }

class FarmButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final FarmButtonStyle style;
  final bool isLoading;
  final bool? isFullWidth;
  final IconData? icon;

  const FarmButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = FarmButtonStyle.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    return SizedBox(
      width: isFullWidth == true ? double.infinity : null,
      height: AppDimensions.buttonHeightLarge,
      child: _buildButton(context, isDisabled),
    );
  }

  Widget _buildButton(BuildContext context, bool isDisabled) {
    final child = isLoading ? _buildLoadingIndicator() : _buildLabelWithIcon();

    final buttonStyle = _getButtonStyle(context);

    // Add haptic feedback wrapper
    final VoidCallback? hapticOnPressed = isDisabled
        ? null
        : () {
            HapticService.light(); // Trigger haptic on press
            onPressed?.call();
          };

    switch (style) {
      case FarmButtonStyle.primary:
      case FarmButtonStyle.secondary:
      case FarmButtonStyle.danger:
        return ElevatedButton(
          onPressed: hapticOnPressed,
          style: buttonStyle,
          child: child,
        );
      case FarmButtonStyle.outline:
        return OutlinedButton(
          onPressed: hapticOnPressed,
          style: buttonStyle,
          child: child,
        );
      case FarmButtonStyle.ghost:
        return TextButton(
          onPressed: hapticOnPressed,
          style: buttonStyle,
          child: child,
        );
    }
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: _getLoadingIndicatorColor(),
      ),
    );
  }

  Widget _buildLabelWithIcon() {
    if (icon == null) {
      return Text(label);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(label)],
    );
  }

  ButtonStyle _getButtonStyle(BuildContext context) {
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppDimensions.radiusL)),
    );

    switch (style) {
      case FarmButtonStyle.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: shape,
          elevation: 0,
        );
      case FarmButtonStyle.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.primaryDark,
          shape: shape,
          elevation: 0,
        );
      case FarmButtonStyle.danger:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          shape: shape,
          elevation: 0,
        );
      case FarmButtonStyle.outline:
        return OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          shape: shape,
        );
      case FarmButtonStyle.ghost:
        return TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          shape: shape,
        );
    }
  }

  Color _getLoadingIndicatorColor() {
    switch (style) {
      case FarmButtonStyle.primary:
      case FarmButtonStyle.danger:
        return Colors.white;
      case FarmButtonStyle.secondary:
        return AppColors.primaryDark;
      case FarmButtonStyle.outline:
      case FarmButtonStyle.ghost:
        return AppColors.primary;
    }
  }
}
