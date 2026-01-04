import 'package:flutter/material.dart';
import 'package:farmdashr/data/repositories/repositories.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

// Services
import 'package:farmdashr/core/services/auth_service.dart';

// Customer pages
import 'package:farmdashr/pages/customer/customer_home_page.dart';
import 'package:farmdashr/pages/customer/customer_profile_page.dart';
import 'package:farmdashr/pages/customer/customer_orders_page.dart';
import 'package:farmdashr/pages/customer/customer_main_screen.dart';
import 'package:farmdashr/pages/customer/customer_browse_page.dart';
import 'package:farmdashr/pages/customer/customer_cart_page.dart';
import 'package:farmdashr/pages/customer/product_detail_page.dart';
import 'package:farmdashr/pages/customer/pre_order_checkout_page.dart';
import 'package:farmdashr/pages/customer/customer_onboarding_page.dart';
import 'package:farmdashr/pages/order_detail_page.dart';
import 'package:farmdashr/data/models/product/product.dart';
import 'package:farmdashr/data/models/order/order.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:farmdashr/data/models/cart/cart_item.dart';

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
import 'package:farmdashr/pages/common/help_support_page.dart';
import 'package:farmdashr/pages/common/edit_profile_page.dart';

/// Routes that don't require authentication
const List<String> _publicRoutes = [
  '/',
  '/login',
  '/signup',
  '/forgot-password',
];

const List<String> _onboardingRoutes = [
  '/customer-onboarding',
  '/farmer-onboarding',
];

/// Application router configuration using GoRouter
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(
    FirebaseAuth.instance.authStateChanges(),
  ),
  redirect: (context, state) async {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isOnPublicRoute = _publicRoutes.contains(state.matchedLocation);
    final isOnOnboardingRoute = _onboardingRoutes.contains(
      state.matchedLocation,
    );

    // If user is on onboarding route and logged in, don't redirect
    if (isLoggedIn && isOnOnboardingRoute) {
      return null;
    }

    // If user is logged in
    if (isLoggedIn) {
      // Check if onboarding is complete for any route (public or protected)
      try {
        final userRepo = FirestoreUserRepository();
        final profile = await userRepo.getCurrentUserProfile();
        if (profile != null && !profile.isOnboardingComplete) {
          // Redirect to appropriate onboarding based on user type
          if (profile.isFarmer) {
            return '/farmer-onboarding';
          }
          return '/customer-onboarding';
        }
      } catch (_) {
        // If we can't check and on public route, redirect to customer onboarding
        if (isOnPublicRoute) {
          return '/customer-onboarding';
        }
      }

      // If on public route and onboarding is complete, go to home
      if (isOnPublicRoute) {
        return '/customer-home';
      }

      // Already on a protected route and onboarding complete, no redirect
      return null;
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
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const FreshMarketOnboarding(),
        state: state,
      ),
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

    // Customer Onboarding (profile setup after signup)
    GoRoute(
      path: '/customer-onboarding',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const CustomerOnboardingPage(),
        state: state,
      ),
    ),

    // Farmer Onboarding
    GoRoute(
      path: '/farmer-onboarding',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const FarmerOnboardingPage(),
        state: state,
      ),
    ),

    // Business Info (outside shell - no bottom nav)
    GoRoute(
      path: '/business-info',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const BusinessInfoPage(),
        state: state,
      ),
    ),

    // Add Product (outside shell - no bottom nav)
    GoRoute(
      path: '/add-product',
      pageBuilder: (context, state) {
        final product = state.extra as Product?;
        return _buildPageWithTransition(
          child: AddProductPage(product: product),
          state: state,
        );
      },
    ),

    // Product Detail (outside shell)
    GoRoute(
      path: '/product-detail',
      pageBuilder: (context, state) {
        final Map<String, dynamic> extra = state.extra as Map<String, dynamic>;
        final product = extra['product'] as Product;
        final isFarmerView = extra['isFarmerView'] as bool? ?? false;
        final heroTag = extra['heroTag'] as String?;
        return _buildPageWithTransition(
          child: ProductDetailPage(
            product: product,
            isFarmerView: isFarmerView,
            heroTag: heroTag,
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
                  future: FirestoreOrderRepository().getById(orderId),
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

    // Help & Support
    GoRoute(
      path: '/help-support',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const HelpSupportPage(),
        state: state,
      ),
    ),

    // Edit Profile
    GoRoute(
      path: '/edit-profile',
      pageBuilder: (context, state) {
        final userProfile = state.extra as UserProfile;
        return _buildPageWithTransition(
          child: EditProfilePage(userProfile: userProfile),
          state: state,
        );
      },
    ),

    // Pre-Order Checkout (outside shell)
    GoRoute(
      path: '/pre-order-checkout',
      pageBuilder: (context, state) {
        // Support buyNowItems for direct purchase mode
        final buyNowItems = state.extra as List<CartItem>?;
        return _buildPageWithTransition(
          child: PreOrderCheckoutPage(buyNowItems: buyNowItems),
          state: state,
        );
      },
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
