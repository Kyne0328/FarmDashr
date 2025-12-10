import 'package:farmdashr/pages/role_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/pages/onboarding.dart';

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
      path: '/farmer-home',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text("Farmer Dashboard"))),
    ),

    GoRoute(
      path: '/customer-home',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text("Customer Home"))),
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
