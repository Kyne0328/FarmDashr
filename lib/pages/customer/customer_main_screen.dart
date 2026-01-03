import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/pages/customer/customer_bottom_nav_bar.dart';
import 'package:farmdashr/blocs/auth/auth_bloc.dart';
import 'package:farmdashr/blocs/notification/notification_bloc.dart';
import 'package:farmdashr/blocs/notification/notification_event.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
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
  @override
  void initState() {
    super.initState();
    _triggerWatch();
  }

  void _triggerWatch() {
    final userId = context.read<AuthBloc>().state.userId;
    if (userId != null) {
      context.read<NotificationBloc>().add(
        WatchNotifications(userId: userId, userType: UserType.customer),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: widget.child,
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
