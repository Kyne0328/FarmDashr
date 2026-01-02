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
import 'package:farmdashr/data/models/product.dart';

// Farmer pages
import 'package:farmdashr/pages/farmer/farmer_home_page.dart';
import 'package:farmdashr/pages/farmer/orders_page.dart';
import 'package:farmdashr/pages/farmer/inventory_page.dart';
import 'package:farmdashr/pages/farmer/profile_page.dart';
import 'package:farmdashr/pages/farmer/farmer_main_screen.dart';
import 'package:farmdashr/pages/farmer/add_product_page.dart';
import 'package:farmdashr/pages/farmer/farmer_onboarding_page.dart';

// Shared pages
import 'package:farmdashr/pages/onboarding.dart';
import 'package:farmdashr/pages/login_screen.dart';
import 'package:farmdashr/pages/signup_screen.dart';
import 'package:farmdashr/pages/forgot_password_screen.dart';

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
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),

    // Farmer Onboarding
    GoRoute(
      path: '/farmer-onboarding',
      builder: (context, state) => const FarmerOnboardingPage(),
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
      builder: (context, state) {
        final Map<String, dynamic> extra = state.extra as Map<String, dynamic>;
        final product = extra['product'] as Product;
        final isFarmerView = extra['isFarmerView'] as bool? ?? false;
        return ProductDetailPage(product: product, isFarmerView: isFarmerView);
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
            return CustomerBrowsePage(initialCategory: category);
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
