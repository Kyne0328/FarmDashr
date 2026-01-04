import 'package:flutter/material.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/services/haptic_service.dart';

/// A premium pill-style tab bar with animated selection indicator.
///
/// Use this for consistent tab navigation across the app.
class PillTabBar extends StatefulWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final Color? activeColor;
  final bool showCounts;
  final List<int>? counts;

  const PillTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
    this.activeColor,
    this.showCounts = false,
    this.counts,
  });

  @override
  State<PillTabBar> createState() => _PillTabBarState();
}

class _PillTabBarState extends State<PillTabBar> {
  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? AppColors.primary;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(AppDimensions.paddingXS),
      decoration: BoxDecoration(
        color: AppColors.containerLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Row(
        children: List.generate(widget.tabs.length, (index) {
          final isActive = widget.selectedIndex == index;
          final label =
              widget.showCounts &&
                  widget.counts != null &&
                  index < widget.counts!.length
              ? '${widget.tabs[index]} (${widget.counts![index]})'
              : widget.tabs[index];

          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticService.selection();
                widget.onTabChanged(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: isActive ? activeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: AppTextStyles.button.copyWith(
                      color: isActive ? Colors.white : AppColors.textSecondary,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                    child: Text(label),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// A simpler version that works with TabController for TabBarView integration
class PillTabBarWithController extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;
  final Color? activeColor;

  const PillTabBarWithController({
    super.key,
    required this.controller,
    required this.tabs,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppColors.primary;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(AppDimensions.paddingXS),
      decoration: BoxDecoration(
        color: AppColors.containerLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: TabBar(
        controller: controller,
        padding: EdgeInsets.zero,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.button.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: AppTextStyles.button.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: tabs.map((label) => Tab(text: label)).toList(),
      ),
    );
  }
}
