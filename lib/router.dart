import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

// Services
import 'package:farmdashr/core/services/auth_service.dart';
import 'package:farmdashr/data/repositories/order/order_repository.dart';

// Customer pages
import 'package:farmdashr/pages/customer/customer_home_page.dart';
import 'package:farmdashr/pages/customer/customer_profile_page.dart';
import 'package:farmdashr/pages/customer/customer_orders_page.dart';
import 'package:farmdashr/pages/customer/customer_main_screen.dart';
import 'package:farmdashr/pages/customer/customer_browse_page.dart';
import 'package:farmdashr/pages/customer/customer_cart_page.dart';
import 'package:farmdashr/pages/customer/product_detail_page.dart';
import 'package:farmdashr/pages/customer/pre_order_checkout_page.dart';
import 'package:farmdashr/pages/order_detail_page.dart';
import 'package:farmdashr/data/models/product/product.dart';
import 'package:farmdashr/data/models/order/order.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';

// Farmer pages
import 'package:farmdashr/pages/farmer/farmer_home_page.dart';
import 'package:farmdashr/pages/farmer/orders_page.dart';
import 'package:farmdashr/pages/farmer/inventory_page.dart';
import 'package:farmdashr/pages/farmer/profile_page.dart';
import 'package:farmdashr/pages/farmer/farmer_main_screen.dart';
import 'package:farmdashr/pages/farmer/add_product_page.dart';
import 'package:farmdashr/pages/farmer/farmer_onboarding_page.dart';
import 'package:farmdashr/pages/farmer/business_info_page.dart';

// Shared pages
import 'package:farmdashr/pages/onboarding.dart';
import 'package:farmdashr/pages/login_screen.dart';
import 'package:farmdashr/pages/signup_screen.dart';
import 'package:farmdashr/pages/forgot_password_screen.dart';
import 'package:farmdashr/pages/notification_page.dart';
import 'package:farmdashr/pages/notification_settings_page.dart';

/// Routes that don't require authentication
const List<String> _publicRoutes = [
  '/',
  '/login',
  '/signup',
  '/forgot-password',
];

/// Application router configuration using GoRouter
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(
    FirebaseAuth.instance.authStateChanges(),
  ),
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isOnPublicRoute = _publicRoutes.contains(state.matchedLocation);

    // If user is logged in and trying to access public routes, redirect to home
    if (isLoggedIn && isOnPublicRoute) {
      return '/customer-home';
    }

    // If user is NOT logged in and trying to access protected routes, redirect to login
    if (!isLoggedIn && !isOnPublicRoute) {
      return '/login';
    }

    // No redirect needed
    return null;
  },
  routes: [
    // Onboarding
    GoRoute(
      path: '/',
      builder: (context, state) => const FreshMarketOnboarding(),
    ),

    // Auth Routes
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) =>
          _buildPageWithTransition(child: const LoginScreen(), state: state),
    ),
    GoRoute(
      path: '/signup',
      pageBuilder: (context, state) =>
          _buildPageWithTransition(child: const SignUpScreen(), state: state),
    ),
    GoRoute(
      path: '/forgot-password',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const ForgotPasswordScreen(),
        state: state,
      ),
    ),

    // Farmer Onboarding
    GoRoute(
      path: '/farmer-onboarding',
      builder: (context, state) => const FarmerOnboardingPage(),
    ),

    // Business Info (outside shell - no bottom nav)
    GoRoute(
      path: '/business-info',
      builder: (context, state) => const BusinessInfoPage(),
    ),

    // Add Product (outside shell - no bottom nav)
    GoRoute(
      path: '/add-product',
      builder: (context, state) {
        final product = state.extra as Product?;
        return AddProductPage(product: product);
      },
    ),

    // Product Detail (outside shell)
    GoRoute(
      path: '/product-detail',
      pageBuilder: (context, state) {
        final Map<String, dynamic> extra = state.extra as Map<String, dynamic>;
        final product = extra['product'] as Product;
        final isFarmerView = extra['isFarmerView'] as bool? ?? false;
        return _buildPageWithTransition(
          child: ProductDetailPage(
            product: product,
            isFarmerView: isFarmerView,
          ),
          state: state,
        );
      },
    ),

    // Order Detail (outside shell)
    GoRoute(
      path: '/order-detail',
      pageBuilder: (context, state) {
        final Map<String, dynamic>? extra =
            state.extra as Map<String, dynamic>?;
        if (extra != null && extra.containsKey('order')) {
          final order = extra['order'] as Order;
          final isFarmerView = extra['isFarmerView'] as bool? ?? false;
          return _buildPageWithTransition(
            child: OrderDetailPage(order: order, isFarmerView: isFarmerView),
            state: state,
          );
        }

        // Handle navigation via ID (e.g., from notifications)
        final orderId = state.uri.queryParameters['id'];
        final isFarmerView = state.uri.queryParameters['isFarmer'] == 'true';

        return _buildPageWithTransition(
          child: orderId != null
              ? FutureBuilder<Order?>(
                  future: OrderRepository().getById(orderId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data == null) {
                      return Scaffold(
                        appBar: AppBar(),
                        body: const Center(child: Text('Order not found')),
                      );
                    }
                    return OrderDetailPage(
                      order: snapshot.data!,
                      isFarmerView: isFarmerView,
                    );
                  },
                )
              : Scaffold(
                  appBar: AppBar(),
                  body: const Center(child: Text('Missing order details')),
                ),
          state: state,
        );
      },
    ),

    // Notifications (outside shell)
    GoRoute(
      path: '/notifications',
      pageBuilder: (context, state) {
        final role = state.uri.queryParameters['role'];
        UserType? userType;
        if (role != null) {
          userType = UserType.values.cast<UserType?>().firstWhere(
            (e) => e?.name == role,
            orElse: () => null,
          );
        }
        return _buildPageWithTransition(
          child: NotificationPage(userType: userType),
          state: state,
        );
      },
    ),

    // Notification Settings
    GoRoute(
      path: '/notification-settings',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const NotificationSettingsPage(),
        state: state,
      ),
    ),

    // Farmer Shell Route (with bottom navigation)
    ShellRoute(
      builder: (context, state, child) {
        return FarmerMainScreen(child: child);
      },
      routes: [
        GoRoute(
          path: '/farmer-home-page',
          pageBuilder: (context, state) => _buildFadeTransitionPage(
            child: const FarmerHomePage(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/orders-page',
          pageBuilder: (context, state) =>
              _buildFadeTransitionPage(child: const OrdersPage(), state: state),
        ),
        GoRoute(
          path: '/inventory-page',
          pageBuilder: (context, state) => _buildFadeTransitionPage(
            child: const InventoryPage(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/profile-page',
          pageBuilder: (context, state) => _buildFadeTransitionPage(
            child: const ProfilePage(),
            state: state,
          ),
        ),
      ],
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
        GoRoute(
          path: '/customer-browse',
          builder: (context, state) {
            // Parse category filter
            final categoryName = state.uri.queryParameters['category'];
            ProductCategory? category;
            if (categoryName != null) {
              category = ProductCategory.values
                  .cast<ProductCategory?>()
                  .firstWhere(
                    (c) => c?.name == categoryName,
                    orElse: () => null,
                  );
            }

            // Parse tab selection (0 = Products, 1 = Vendors)
            final tabName = state.uri.queryParameters['tab'];
            int tabIndex = 0;
            if (tabName == 'vendors') {
              tabIndex = 1;
            }

            // Parse search query
            final searchQuery = state.uri.queryParameters['q'];

            return CustomerBrowsePage(
              initialCategory: category,
              initialTabIndex: tabIndex,
              initialSearchQuery: searchQuery,
            );
          },
        ),
        GoRoute(
          path: '/customer-cart',
          builder: (context, state) => const CustomerCartPage(),
        ),
        GoRoute(
          path: '/pre-order-checkout',
          builder: (context, state) => const PreOrderCheckoutPage(),
        ),
      ],
    ),
  ],
);

/// Helper to build a page with a fade/slide transition for pushed routes
CustomTransitionPage _buildPageWithTransition({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(CurveTween(curve: Curves.easeOutCubic).animate(animation)),
          child: child,
        ),
      );
    },
  );
}

/// Helper to build a page with a quick fade transition for tab navigation
CustomTransitionPage _buildFadeTransitionPage({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 150),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeOut).animate(animation),
        child: child,
      );
    },
  );
}
