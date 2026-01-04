import 'package:flutter/material.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/data/models/order/order.dart';

/// A reusable status badge widget used across the app.
/// Follows Open/Closed Principle - new badge types can be added without modifying existing code.
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeTheme theme;
  final EdgeInsets? padding;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.theme,
    this.padding,
    this.icon,
  });

  /// Factory constructor for order status badges
  factory StatusBadge.fromOrderStatus(OrderStatus status, {IconData? icon}) {
    return StatusBadge(
      label: status.displayName,
      theme: _getThemeForOrderStatus(status),
      icon: icon,
    );
  }

  /// Factory constructor for certification badges
  factory StatusBadge.certification({
    required String label,
    required CertificationBadgeType type,
  }) {
    return StatusBadge(
      label: label,
      theme: type == CertificationBadgeType.organic
          ? const OrganicCertificationTheme()
          : const LocalProducerTheme(),
    );
  }

  /// Factory constructor for account type badges
  factory StatusBadge.accountType({required String label}) {
    return StatusBadge(label: label, theme: const AccountTypeBadgeTheme());
  }

  /// Factory constructor for low stock badges
  factory StatusBadge.lowStock() {
    return const StatusBadge(label: 'Low', theme: LowStockBadgeTheme());
  }

  static StatusBadgeTheme _getThemeForOrderStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.preparing:
        return const PreparingStatusTheme();
      case OrderStatus.ready:
        return const ReadyStatusTheme();
      case OrderStatus.pending:
        return const PendingStatusTheme();
      case OrderStatus.completed:
        return const CompletedStatusTheme();
      case OrderStatus.cancelled:
        return const CancelledStatusTheme();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ??
          const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingS,
            vertical: AppDimensions.paddingXS,
          ),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(theme.borderRadius),
        border: theme.borderColor != null
            ? Border.all(color: theme.borderColor!, width: 1.5)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: theme.textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: theme.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Theme configuration for StatusBadge.
abstract class StatusBadgeTheme {
  Color get backgroundColor;
  Color get textColor;
  Color? get borderColor => null;
  double get borderRadius;

  const StatusBadgeTheme();
}

// Order Status Themes

class ReadyStatusTheme extends StatusBadgeTheme {
  const ReadyStatusTheme();

  @override
  Color get backgroundColor => AppColors.successLight;
  @override
  Color? get borderColor => AppColors.successBorder;
  @override
  Color get textColor => AppColors.successDark;
  @override
  double get borderRadius => AppDimensions.radiusL;
}

class PreparingStatusTheme extends StatusBadgeTheme {
  const PreparingStatusTheme();

  @override
  Color get backgroundColor => AppColors.actionPurpleLight;
  @override
  Color? get borderColor => AppColors.actionPurple;
  @override
  Color get textColor => AppColors.actionPurple;
  @override
  double get borderRadius => AppDimensions.radiusL;
}

class PendingStatusTheme extends StatusBadgeTheme {
  const PendingStatusTheme();

  @override
  Color get backgroundColor => AppColors.warningLight;
  @override
  Color? get borderColor => AppColors.warningBorder;
  @override
  Color get textColor => AppColors.warningDark;
  @override
  double get borderRadius => AppDimensions.radiusL;
}

class CompletedStatusTheme extends StatusBadgeTheme {
  const CompletedStatusTheme();

  @override
  Color get backgroundColor => AppColors.infoLight;
  @override
  Color? get borderColor => AppColors.infoBorder;
  @override
  Color get textColor => AppColors.infoDark;
  @override
  double get borderRadius => AppDimensions.radiusL;
}

class CancelledStatusTheme extends StatusBadgeTheme {
  const CancelledStatusTheme();

  @override
  Color get backgroundColor => AppColors.errorLight;
  @override
  Color? get borderColor => AppColors.errorLight;
  @override
  Color get textColor => AppColors.error;
  @override
  double get borderRadius => AppDimensions.radiusL;
}

// Certification Themes

class OrganicCertificationTheme extends StatusBadgeTheme {
  const OrganicCertificationTheme();

  @override
  Color get backgroundColor => AppColors.successLight;
  @override
  Color get textColor => AppColors.primaryDark;
  @override
  double get borderRadius => AppDimensions.radiusS;
}

class LocalProducerTheme extends StatusBadgeTheme {
  const LocalProducerTheme();

  @override
  Color get backgroundColor => AppColors.infoLight;
  @override
  Color get textColor => AppColors.infoDark;
  @override
  double get borderRadius => AppDimensions.radiusM;
}

// Account Type Theme

class AccountTypeBadgeTheme extends StatusBadgeTheme {
  const AccountTypeBadgeTheme();

  @override
  Color get backgroundColor => AppColors.successLight;
  @override
  Color get textColor => AppColors.primaryDark;
  @override
  double get borderRadius => AppDimensions.radiusL;
}

// Low Stock Theme

class LowStockBadgeTheme extends StatusBadgeTheme {
  const LowStockBadgeTheme();

  @override
  Color get backgroundColor => AppColors.badgeOrange;
  @override
  Color get textColor => Colors.white;
  @override
  double get borderRadius => AppDimensions.radiusL;
}

/// Certification badge type enum
enum CertificationBadgeType { organic, local }
