import 'package:flutter/material.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';

/// A reusable stat card widget used across the app.
/// Follows Open/Closed Principle - configurable via StatCardTheme.
class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? change;
  final StatCardTheme theme;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.change,
    this.theme = const DefaultStatCardTheme(),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(AppDimensions.paddingXL),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(
          color: theme.borderColor,
          width: AppDimensions.borderWidthThick,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon container (optional - only shown if theme specifies)
          if (theme.showIconContainer)
            Container(
              width: AppDimensions.statCardIconContainer,
              height: AppDimensions.statCardIconContainer,
              decoration: BoxDecoration(
                color: theme.iconBackgroundColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Icon(
                icon,
                size: AppDimensions.iconM,
                color: theme.iconColor,
              ),
            )
          else
            Row(
              children: [
                Icon(icon, size: AppDimensions.iconM, color: theme.iconColor),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.body2.copyWith(
                      color: theme.titleColor,
                    ),
                  ),
                ),
              ],
            ),

          if (theme.showIconContainer) ...[
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              title,
              style: AppTextStyles.caption.copyWith(color: theme.titleColor),
            ),
          ],

          SizedBox(
            height: theme.showIconContainer
                ? AppDimensions.spacingXS
                : AppDimensions.spacingS,
          ),

          Text(
            value,
            style: AppTextStyles.statValue.copyWith(color: theme.valueColor),
          ),

          if (change != null) ...[
            SizedBox(
              height: theme.showIconContainer
                  ? AppDimensions.spacingXS
                  : AppDimensions.spacingS,
            ),
            Text(
              change!,
              style: AppTextStyles.statChange.copyWith(
                color: theme.changeColor,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

/// Theme configuration for StatCard.
/// Follows Interface Segregation - clients only need properties they use.
abstract class StatCardTheme {
  Color get backgroundColor;
  Color get borderColor;
  Color get iconColor;
  Color get iconBackgroundColor;
  Color get titleColor;
  Color get valueColor;
  Color get changeColor;
  bool get showIconContainer;

  const StatCardTheme();
}

/// Default theme for stat cards
class DefaultStatCardTheme extends StatCardTheme {
  const DefaultStatCardTheme();

  @override
  Color get backgroundColor => AppColors.surface;
  @override
  Color get borderColor => AppColors.border;
  @override
  Color get iconColor => AppColors.textTertiary;
  @override
  Color get iconBackgroundColor => AppColors.containerLight;
  @override
  Color get titleColor => AppColors.textTertiary;
  @override
  Color get valueColor => AppColors.textPrimary;
  @override
  Color get changeColor => AppColors.success;
  @override
  bool get showIconContainer => false;
}

class SuccessStatCardTheme extends StatCardTheme {
  const SuccessStatCardTheme();

  @override
  Color get backgroundColor => AppColors.surface;
  @override
  Color get borderColor => AppColors.border;
  @override
  Color get iconColor => AppColors.success;
  @override
  Color get iconBackgroundColor => AppColors.successBackground;
  @override
  Color get titleColor => AppColors.textSecondary;
  @override
  Color get valueColor => AppColors.textPrimary;
  @override
  Color get changeColor => AppColors.success;
  @override
  bool get showIconContainer => true;
}

class InfoStatCardTheme extends StatCardTheme {
  const InfoStatCardTheme();

  @override
  Color get backgroundColor => AppColors.surface;
  @override
  Color get borderColor => AppColors.border;
  @override
  Color get iconColor => AppColors.info;
  @override
  Color get iconBackgroundColor => AppColors.infoBackground;
  @override
  Color get titleColor => AppColors.textSecondary;
  @override
  Color get valueColor => AppColors.textPrimary;
  @override
  Color get changeColor => AppColors.success;
  @override
  bool get showIconContainer => true;
}

class WarningStatCardTheme extends StatCardTheme {
  const WarningStatCardTheme();

  @override
  Color get backgroundColor => AppColors.warningBackground;
  @override
  Color get borderColor => AppColors.warningLight;
  @override
  Color get iconColor => AppColors.warning;
  @override
  Color get iconBackgroundColor => AppColors.warningLight;
  @override
  Color get titleColor => AppColors.warningText;
  @override
  Color get valueColor => AppColors.warningText;
  @override
  Color get changeColor => AppColors.warningDark;
  @override
  bool get showIconContainer => false;
}
