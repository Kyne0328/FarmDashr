import 'package:farmdashr/pages/customer_login_screen.dart';
import 'package:farmdashr/pages/customer_registration_screen.dart';
import 'package:farmdashr/pages/customer_home_page.dart';
import 'package:farmdashr/pages/customer_profile_page.dart';
import 'package:farmdashr/pages/customer_orders_page.dart';
import 'package:farmdashr/pages/customer_main_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:farmdashr/pages/farmer_home_page.dart';
import 'package:farmdashr/pages/orders_page.dart';
import 'package:farmdashr/pages/role_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/pages/onboarding.dart';
import 'package:farmdashr/pages/farmer_login_screen.dart';
import 'package:farmdashr/pages/farmer_registration_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      path: '/farmer-registration-screen',
      builder: (context, state) => const FarmerRegistrationScreen(),
    ),
    GoRoute(
      path: '/customer-registration-screen',
      builder: (context, state) => const CustomerRegistrationScreen(),
    ),
    GoRoute(
      path: '/customer-login',
      builder: (context, state) => const CustomerLoginScreen(),
    ),

    // ShellRoute for Customer pages
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
