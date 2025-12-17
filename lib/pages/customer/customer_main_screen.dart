import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/pages/customer/customer_bottom_nav_bar.dart';

/// Main screen wrapper for customer pages with shared bottom navigation.
/// Uses CustomerBottomNavBar for consistent navigation across customer pages.
class CustomerMainScreen extends StatelessWidget {
  final Widget child;

  const CustomerMainScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: CustomerBottomNavBar(
        currentItem: _getCurrentNavItem(context),
      ),
    );
  }

  /// Determines the current nav item based on the current route.
  CustomerNavItem _getCurrentNavItem(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;

    if (location.startsWith('/customer-home')) {
      return CustomerNavItem.home;
    }
    if (location.startsWith('/customer-browse')) {
      return CustomerNavItem.browse;
    }
    if (location.startsWith('/customer-cart')) {
      return CustomerNavItem.cart;
    }
    if (location.startsWith('/customer-orders')) {
      return CustomerNavItem.orders;
    }
    if (location.startsWith('/customer-profile')) {
      return CustomerNavItem.profile;
    }
    return CustomerNavItem.home;
  }
}
