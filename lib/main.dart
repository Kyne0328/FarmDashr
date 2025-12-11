import 'package:farmdashr/pages/customer_login_screen.dart';
import 'package:farmdashr/pages/farmer_home_page.dart';
import 'package:farmdashr/pages/orders_page.dart';
import 'package:farmdashr/pages/role_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/pages/onboarding.dart';
import 'package:farmdashr/pages/farmer_login_screen.dart';
import 'package:farmdashr/pages/account_registration_screen.dart';

void main() {
  runApp(const MainApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const FreshMarketOnboarding(),
    ),

    GoRoute(
      path: '/role-selection',
      builder: (context, state) => const RoleSelectionScreen(),
    ),

    GoRoute(
      path: '/farmer-login',
      builder: (context, state) => const FarmerLoginScreen(),
    ),
    GoRoute(
      path: '/account-registration',
      builder: (context, state) => const AccountRegistrationScreen(),
    ),
    GoRoute(
      path: '/customer-home',
      builder: (context, state) => const CustomerLoginScreen(),
    ),
    GoRoute(
      path: '/farmer-home-page',
      builder: (context, state) => const FarmerHomePage(),
    ),
    GoRoute(
      path: '/orders-page',
      builder: (context, state) => const OrdersPage(),
    ),
  ],
);

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(useMaterial3: true),
    );
  }
}
