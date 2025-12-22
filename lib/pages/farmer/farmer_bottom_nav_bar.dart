import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';

/// Navigation item enum for farmer pages
enum FarmerNavItem {
  home,
  orders,
  inventory,
  profile;

  String get label {
    switch (this) {
      case FarmerNavItem.home:
        return 'Home';
      case FarmerNavItem.orders:
        return 'Orders';
      case FarmerNavItem.inventory:
        return 'Inventory';
      case FarmerNavItem.profile:
        return 'Profile';
    }
  }

  IconData get icon {
    switch (this) {
      case FarmerNavItem.home:
        return Icons.home_outlined;
      case FarmerNavItem.orders:
        return Icons.receipt_long_outlined;
      case FarmerNavItem.inventory:
        return Icons.inventory_2_outlined;
      case FarmerNavItem.profile:
        return Icons.person_outline;
    }
  }

  String get route {
    switch (this) {
      case FarmerNavItem.home:
        return '/farmer-home-page';
      case FarmerNavItem.orders:
        return '/orders-page';
      case FarmerNavItem.inventory:
        return '/inventory-page';
      case FarmerNavItem.profile:
        return '/profile-page';
    }
  }
}

/// Shared bottom navigation bar for all farmer pages.
/// Follows Single Responsibility Principle - only handles navigation.
/// Follows DRY principle - eliminates duplication across farmer pages.
class FarmerBottomNavBar extends StatelessWidget {
  final FarmerNavItem currentItem;

  const FarmerBottomNavBar({super.key, required this.currentItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: AppDimensions.borderWidth,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: FarmerNavItem.values.map((item) {
            return Expanded(
              child: _NavItem(
                icon: item.icon,
                label: item.label,
                isActive: item == currentItem,
                onTap: () {
                  if (item != currentItem) {
                    context.go(item.route);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.navLabel.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
