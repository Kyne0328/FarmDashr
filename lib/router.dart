import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:farmdashr/data/repositories/repositories.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        final userRepo = context.read<UserRepository>();
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
      pageBuilder: (context, state) => _buildStandardPageTransition(
        child: const FreshMarketOnboarding(),
        state: state,
      ),
    ),

    // Auth Routes
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _buildStandardPageTransition(
        child: const LoginScreen(),
        state: state,
      ),
    ),
    GoRoute(
      path: '/signup',
      pageBuilder: (context, state) => _buildStandardPageTransition(
        child: const SignUpScreen(),
        state: state,
      ),
    ),
    GoRoute(
      path: '/forgot-password',
      pageBuilder: (context, state) => _buildStandardPageTransition(
        child: const ForgotPasswordScreen(),
        state: state,
      ),
    ),

    // Customer Onboarding (profile setup after signup)
    GoRoute(
      path: '/customer-onboarding',
      pageBuilder: (context, state) => _buildStandardPageTransition(
        child: const CustomerOnboardingPage(),
        state: state,
      ),
    ),

    // Farmer Onboarding
    GoRoute(
      path: '/farmer-onboarding',
      pageBuilder: (context, state) => _buildStandardPageTransition(
        child: const FarmerOnboardingPage(),
        state: state,
      ),
    ),

    // Business Info (outside shell - no bottom nav)
    GoRoute(
      path: '/business-info',
      pageBuilder: (context, state) => _buildStandardPageTransition(
        child: const BusinessInfoPage(),
        state: state,
      ),
    ),

    // Add Product (outside shell - no bottom nav)
    GoRoute(
      path: '/add-product',
      pageBuilder: (context, state) {
        // Safely handle optional Product parameter
        Product? product;
        if (state.extra != null) {
          if (state.extra is Product) {
            product = state.extra as Product;
          }
        }
        return _buildStandardPageTransition(
          child: AddProductPage(product: product),
          state: state,
        );
      },
    ),

    // Product Detail (outside shell)
    GoRoute(
      path: '/product-detail',
      pageBuilder: (context, state) {
        // Type-safe extraction of navigation parameters
        if (state.extra is! Map<String, dynamic>) {
          return _buildStandardPageTransition(
            child: Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(
                child: Text('Invalid navigation data. Please try again.'),
              ),
            ),
            state: state,
          );
        }

        final extra = state.extra as Map<String, dynamic>;
        if (extra['product'] is! Product) {
          return _buildStandardPageTransition(
            child: Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(child: Text('Product data not found.')),
            ),
            state: state,
          );
        }

        final product = extra['product'] as Product;
        final isFarmerView = extra['isFarmerView'] is bool
            ? extra['isFarmerView'] as bool
            : false;
        final heroTag = extra['heroTag'] is String
            ? extra['heroTag'] as String
            : null;

        return _buildStandardPageTransition(
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
        // Type-safe extraction with validation
        Map<String, dynamic>? extra;
        if (state.extra != null) {
          if (state.extra is Map<String, dynamic>) {
            extra = state.extra as Map<String, dynamic>;
          } else {
            // Invalid type - show error
            return _buildStandardPageTransition(
              child: Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text('Invalid navigation data.')),
              ),
              state: state,
            );
          }
        }

        // If extra data provided, validate and use it
        if (extra != null && extra.containsKey('order')) {
          if (extra['order'] is! Order) {
            return _buildStandardPageTransition(
              child: Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(child: Text('Invalid order data.')),
              ),
              state: state,
            );
          }

          final order = extra['order'] as Order;
          final isFarmerView = extra['isFarmerView'] is bool
              ? extra['isFarmerView'] as bool
              : false;
          return _buildStandardPageTransition(
            child: OrderDetailPage(order: order, isFarmerView: isFarmerView),
            state: state,
          );
        }

        // Handle navigation via ID (e.g., from notifications)
        final orderId = state.uri.queryParameters['id'];
        final isFarmerView = state.uri.queryParameters['isFarmer'] == 'true';

        return _buildStandardPageTransition(
          child: orderId != null
              ? FutureBuilder<Order?>(
                  future: context.read<OrderRepository>().getById(orderId),
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
                        appBar: AppBar(title: const Text('Error')),
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
                  appBar: AppBar(title: const Text('Error')),
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
        return _buildStandardPageTransition(
          child: NotificationPage(userType: userType),
          state: state,
        );
      },
    ),

    // Notification Settings
    GoRoute(
      path: '/notification-settings',
      pageBuilder: (context, state) => _buildStandardPageTransition(
        child: const NotificationSettingsPage(),
        state: state,
      ),
    ),

    // Help & Support
    GoRoute(
      path: '/help-support',
      pageBuilder: (context, state) => _buildStandardPageTransition(
        child: const HelpSupportPage(),
        state: state,
      ),
    ),

    // Edit Profile
    GoRoute(
      path: '/edit-profile',
      pageBuilder: (context, state) {
        // Validate UserProfile data
        if (state.extra is! UserProfile) {
          return _buildStandardPageTransition(
            child: Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(
                child: Text(
                  'Profile data not found. Please try again from the profile page.',
                ),
              ),
            ),
            state: state,
          );
        }

        final userProfile = state.extra as UserProfile;
        return _buildStandardPageTransition(
          child: EditProfilePage(userProfile: userProfile),
          state: state,
        );
      },
    ),

    // Pre-Order Checkout (outside shell)
    GoRoute(
      path: '/pre-order-checkout',
      pageBuilder: (context, state) {
        // Safely extract optional buyNowItems for direct purchase mode
        List<CartItem>? buyNowItems;
        if (state.extra != null) {
          if (state.extra is List<CartItem>) {
            buyNowItems = state.extra as List<CartItem>;
          } else if (state.extra is List) {
            // Validate that all items in the list are CartItems
            final list = state.extra as List;
            if (list.every((item) => item is CartItem)) {
              buyNowItems = list.cast<CartItem>();
              // Skip invalid items
            }
          } else {
            // Invalid type passed
          }
        }

        return _buildStandardPageTransition(
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
          pageBuilder: (context, state) => _buildStandardPageTransition(
            child: const FarmerHomePage(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/orders-page',
          pageBuilder: (context, state) => _buildStandardPageTransition(
            child: const OrdersPage(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/inventory-page',
          pageBuilder: (context, state) => _buildStandardPageTransition(
            child: const InventoryPage(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/profile-page',
          pageBuilder: (context, state) => _buildStandardPageTransition(
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
          pageBuilder: (context, state) => _buildStandardPageTransition(
            child: const CustomerHomePage(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/customer-profile',
          pageBuilder: (context, state) => _buildStandardPageTransition(
            child: const CustomerProfilePage(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/customer-orders',
          pageBuilder: (context, state) => _buildStandardPageTransition(
            child: const CustomerOrdersPage(),
            state: state,
          ),
        ),
        GoRoute(
          path: '/customer-browse',
          pageBuilder: (context, state) {
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

            return _buildStandardPageTransition(
              child: CustomerBrowsePage(
                initialCategory: category,
                initialTabIndex: tabIndex,
                initialSearchQuery: searchQuery,
              ),
              state: state,
            );
          },
        ),
        GoRoute(
          path: '/customer-cart',
          pageBuilder: (context, state) => _buildStandardPageTransition(
            child: const CustomerCartPage(),
            state: state,
          ),
        ),
      ],
    ),
  ],
);

/// Helper to build a consistent page transition for all routes
CustomTransitionPage _buildStandardPageTransition({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 150),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return CupertinoPageTransition(
        primaryRouteAnimation: animation,
        secondaryRouteAnimation: secondaryAnimation,
        linearTransition: true,
        child: child,
      );
    },
  );
}
