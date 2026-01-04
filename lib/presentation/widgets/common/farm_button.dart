import 'package:flutter/material.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/services/haptic_service.dart';

enum FarmButtonStyle { primary, secondary, outline, ghost, danger }

class FarmButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final FarmButtonStyle style;
  final bool isLoading;
  final bool? isFullWidth;
  final IconData? icon;

  // Customization overrides
  final double? width;
  final double? height;
  final Color? textColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? textSize;

  const FarmButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = FarmButtonStyle.primary,
    this.isLoading = false,
    this.isFullWidth,
    this.icon,
    this.width,
    this.height,
    this.textColor,
    this.backgroundColor,
    this.borderColor,
    this.textSize,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    // Determine width: explicit width > isFullWidth > null (intrinsic)
    double? effectiveWidth = width;
    if (effectiveWidth == null && isFullWidth == true) {
      effectiveWidth = double.infinity;
    }

    return SizedBox(
      width: effectiveWidth,
      height: height ?? AppDimensions.buttonHeightLarge,
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
    final textStyle = AppTextStyles.button.copyWith(
      fontSize: textSize,
      color: textColor ?? _getDefaultTextColor(),
    );

    if (icon == null) {
      return Text(label, style: textStyle);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: textStyle.color),
        const SizedBox(width: 8),
        Text(label, style: textStyle),
      ],
    );
  }

  ButtonStyle _getButtonStyle(BuildContext context) {
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppDimensions.radiusL)),
    );

    // Reduced padding for compact buttons
    const compactPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 4);

    switch (style) {
      case FarmButtonStyle.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: textColor ?? Colors.white,
          shape: shape,
          elevation: 0,
          padding: compactPadding,
          alignment: Alignment.center,
        );
      case FarmButtonStyle.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primaryLight,
          foregroundColor: textColor ?? AppColors.primaryDark,
          shape: shape,
          elevation: 0,
          padding: compactPadding,
          alignment: Alignment.center,
        );
      case FarmButtonStyle.danger:
        return ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.error,
          foregroundColor: textColor ?? Colors.white,
          shape: shape,
          elevation: 0,
          padding: compactPadding,
          alignment: Alignment.center,
        );
      case FarmButtonStyle.outline:
        return OutlinedButton.styleFrom(
          foregroundColor: textColor ?? AppColors.textPrimary,
          side: BorderSide(color: borderColor ?? AppColors.border),
          shape: shape,
          backgroundColor: backgroundColor,
          padding: compactPadding,
          alignment: Alignment.center,
        );
      case FarmButtonStyle.ghost:
        return TextButton.styleFrom(
          foregroundColor: textColor ?? AppColors.textSecondary,
          shape: shape,
          backgroundColor: backgroundColor,
          padding: compactPadding,
          alignment: Alignment.center,
        );
    }
  }

  Color _getDefaultTextColor() {
    switch (style) {
      case FarmButtonStyle.primary:
      case FarmButtonStyle.danger:
        return Colors.white;
      case FarmButtonStyle.secondary:
        return AppColors.primaryDark;
      case FarmButtonStyle.outline:
        return AppColors.textPrimary;
      case FarmButtonStyle.ghost:
        return AppColors.textSecondary;
    }
  }

  Color _getLoadingIndicatorColor() {
    if (textColor != null) return textColor!;

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
