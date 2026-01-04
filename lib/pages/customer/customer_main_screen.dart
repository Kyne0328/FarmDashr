import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/pages/customer/customer_bottom_nav_bar.dart';
import 'package:farmdashr/blocs/auth/auth_bloc.dart';
import 'package:farmdashr/blocs/notification/notification_bloc.dart';
import 'package:farmdashr/blocs/notification/notification_event.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:farmdashr/blocs/order/order.dart';
import 'package:farmdashr/blocs/product/product.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Main screen wrapper for customer pages with shared bottom navigation.
/// Uses CustomerBottomNavBar for consistent navigation across customer pages.
class CustomerMainScreen extends StatefulWidget {
  final Widget child;

  const CustomerMainScreen({super.key, required this.child});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
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
        WatchNotifications(userId: userId, userType: UserType.customer),
      );
      // Watch customer orders
      context.read<OrderBloc>().add(WatchCustomerOrders(userId));
      // Ensure products are loaded (without farmer filter)
      context.read<ProductBloc>().add(const LoadProducts());
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
          if (currentNav != CustomerNavItem.home) {
            // If not on home tab, go to home
            context.go('/customer-home');
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
