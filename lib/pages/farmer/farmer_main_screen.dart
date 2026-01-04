import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/pages/farmer/farmer_bottom_nav_bar.dart';
import 'package:farmdashr/blocs/auth/auth_bloc.dart';
import 'package:farmdashr/blocs/notification/notification_bloc.dart';
import 'package:farmdashr/blocs/notification/notification_event.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:farmdashr/blocs/order/order.dart';
import 'package:farmdashr/blocs/product/product.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Main screen wrapper for farmer pages with shared bottom navigation.
/// Uses FarmerBottomNavBar for consistent navigation across farmer pages.
class FarmerMainScreen extends StatefulWidget {
  final Widget child;

  const FarmerMainScreen({super.key, required this.child});

  @override
  State<FarmerMainScreen> createState() => _FarmerMainScreenState();
}

class _FarmerMainScreenState extends State<FarmerMainScreen> {
  DateTime? _lastBackPressTime;
  @override
  void initState() {
    super.initState();
    _triggerWatch();
  }

  void _triggerWatch() {
    final authState = context.read<AuthBloc>().state;
    final userId = authState.userId;
    if (userId != null) {
      context.read<NotificationBloc>().add(
        WatchNotifications(userId: userId, userType: UserType.farmer),
      );
      // Watch farmer orders
      context.read<OrderBloc>().add(WatchFarmerOrders(userId));
      // Load farmer products for inventory/stats
      context.read<ProductBloc>().add(LoadProducts(farmerId: userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;

          final currentNav = _getCurrentNavItem(context);
          if (currentNav != FarmerNavItem.home) {
            // If not on home tab, go to home
            context.go('/farmer-home-page');
            return;
          }

          // If on home tab, handle double back to exit
          final now = DateTime.now();
          if (_lastBackPressTime == null ||
              now.difference(_lastBackPressTime!) >
                  const Duration(seconds: 2)) {
            _lastBackPressTime = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Press back again to exit'),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }

          // Let system handle exit
          await SystemNavigator.pop();
        },
        child: widget.child,
      ),
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
