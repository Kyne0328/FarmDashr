import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/services/haptic_service.dart';

/// Navigation item enum for customer pages
enum CustomerNavItem {
  home,
  browse,
  cart,
  orders,
  profile;

  String get label {
    switch (this) {
      case CustomerNavItem.home:
        return 'Home';
      case CustomerNavItem.browse:
        return 'Browse';
      case CustomerNavItem.cart:
        return 'Cart';
      case CustomerNavItem.orders:
        return 'Orders';
      case CustomerNavItem.profile:
        return 'Profile';
    }
  }

  IconData get icon {
    switch (this) {
      case CustomerNavItem.home:
        return Icons.home_outlined;
      case CustomerNavItem.browse:
        return Icons.search;
      case CustomerNavItem.cart:
        return Icons.shopping_cart_outlined;
      case CustomerNavItem.orders:
        return Icons.list_alt_outlined;
      case CustomerNavItem.profile:
        return Icons.person_outline;
    }
  }

  IconData get activeIcon {
    switch (this) {
      case CustomerNavItem.home:
        return Icons.home;
      case CustomerNavItem.browse:
        return Icons.search;
      case CustomerNavItem.cart:
        return Icons.shopping_cart;
      case CustomerNavItem.orders:
        return Icons.list_alt;
      case CustomerNavItem.profile:
        return Icons.person;
    }
  }

  String get route {
    switch (this) {
      case CustomerNavItem.home:
        return '/customer-home';
      case CustomerNavItem.browse:
        return '/customer-browse';
      case CustomerNavItem.cart:
        return '/customer-cart';
      case CustomerNavItem.orders:
        return '/customer-orders';
      case CustomerNavItem.profile:
        return '/customer-profile';
    }
  }

  bool get isImplemented {
    switch (this) {
      case CustomerNavItem.home:
      case CustomerNavItem.orders:
      case CustomerNavItem.profile:
      case CustomerNavItem.browse:
      case CustomerNavItem.cart:
        return true;
    }
  }
}

/// Shared bottom navigation bar for all customer pages.
/// Follows Single Responsibility Principle - only handles navigation.
/// Follows DRY principle - eliminates duplication across customer pages.
class CustomerBottomNavBar extends StatelessWidget {
  final CustomerNavItem currentItem;

  const CustomerBottomNavBar({super.key, required this.currentItem});

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
          children: CustomerNavItem.values.map((item) {
            return Expanded(
              child: _NavItem(
                icon: item == currentItem ? item.activeIcon : item.icon,
                label: item.label,
                isActive: item == currentItem,
                onTap: () {
                  if (item != currentItem && item.isImplemented) {
                    HapticService.selection();
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
    final color = isActive ? AppColors.info : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingS),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: AppDimensions.iconL, color: color),
            const SizedBox(height: AppDimensions.spacingXS),
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
