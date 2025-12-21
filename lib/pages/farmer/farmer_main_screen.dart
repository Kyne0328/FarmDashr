import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/pages/farmer/farmer_bottom_nav_bar.dart';

/// Main screen wrapper for farmer pages with shared bottom navigation.
/// Uses FarmerBottomNavBar for consistent navigation across farmer pages.
class FarmerMainScreen extends StatelessWidget {
  final Widget child;

  const FarmerMainScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: FarmerBottomNavBar(
        currentItem: _getCurrentNavItem(context),
      ),
    );
  }

  /// Determines the current nav item based on the current route.
  FarmerNavItem _getCurrentNavItem(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;

    if (location.startsWith('/farmer-home')) {
      return FarmerNavItem.home;
    }
    if (location.startsWith('/orders')) {
      return FarmerNavItem.orders;
    }
    if (location.startsWith('/inventory')) {
      return FarmerNavItem.inventory;
    }
    if (location.startsWith('/profile')) {
      return FarmerNavItem.profile;
    }
    return FarmerNavItem.home;
  }
}
