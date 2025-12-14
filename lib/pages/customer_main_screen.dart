import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomerMainScreen extends StatelessWidget {
  final Widget child;

  const CustomerMainScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (int index) => _onItemTapped(index, context),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1347E5),
        unselectedItemColor: const Color(0xFF6B7280),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Browse'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Orders'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/customer-home')) {
      return 0;
    }
    if (location.startsWith('/customer-browse')) {
      return 1;
    }
    if (location.startsWith('/customer-cart')) {
      return 2;
    }
    if (location.startsWith('/customer-orders')) {
      return 3;
    }
    if (location.startsWith('/customer-profile')) {
      return 4;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/customer-home');
        break;
      case 1:
        // context.go('/customer-browse'); // To be implemented
        break;
      case 2:
        // context.go('/customer-cart'); // To be implemented
        break;
      case 3:
        context.go('/customer-orders');
        break;
      case 4:
        context.go('/customer-profile');
        break;
    }
  }
}
