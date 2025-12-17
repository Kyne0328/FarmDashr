import 'package:go_router/go_router.dart';

// Customer pages
import 'package:farmdashr/pages/customer/customer_home_page.dart';
import 'package:farmdashr/pages/customer/customer_profile_page.dart';
import 'package:farmdashr/pages/customer/customer_orders_page.dart';
import 'package:farmdashr/pages/customer/customer_main_screen.dart';

// Farmer pages
import 'package:farmdashr/pages/farmer/farmer_home_page.dart';
import 'package:farmdashr/pages/farmer/orders_page.dart';
import 'package:farmdashr/pages/farmer/inventory_page.dart';
import 'package:farmdashr/pages/farmer/profile_page.dart';

// Shared pages
import 'package:farmdashr/pages/onboarding.dart';

/// Application router configuration using GoRouter
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Onboarding
    GoRoute(
      path: '/',
      builder: (context, state) => const FreshMarketOnboarding(),
    ),

    // Farmer Routes
    GoRoute(
      path: '/farmer-home-page',
      builder: (context, state) => const FarmerHomePage(),
    ),
    GoRoute(
      path: '/orders-page',
      builder: (context, state) => const OrdersPage(),
    ),
    GoRoute(
      path: '/inventory-page',
      builder: (context, state) => const InventoryPage(),
    ),
    GoRoute(
      path: '/profile-page',
      builder: (context, state) => const ProfilePage(),
    ),

    // Customer Shell Route (with bottom navigation)
    ShellRoute(
      builder: (context, state, child) {
        return CustomerMainScreen(child: child);
      },
      routes: [
        GoRoute(
          path: '/customer-home',
          builder: (context, state) => const CustomerHomePage(),
        ),
        GoRoute(
          path: '/customer-profile',
          builder: (context, state) => const CustomerProfilePage(),
        ),
        GoRoute(
          path: '/customer-orders',
          builder: (context, state) => const CustomerOrdersPage(),
        ),
      ],
    ),
  ],
);
