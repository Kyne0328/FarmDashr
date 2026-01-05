import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'router.dart';
import 'blocs/product/product.dart';
import 'blocs/order/order.dart';
import 'blocs/cart/cart.dart';
import 'blocs/auth/auth.dart';
import 'blocs/vendor/vendor.dart';
import 'blocs/notification/notification.dart';
import 'data/repositories/repositories.dart';
import 'core/services/auth_service.dart';
import 'core/services/google_auth_service.dart';
import 'core/services/in_app_notification_service.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthService>(create: (context) => AuthService()),
        RepositoryProvider<GoogleAuthService>(
          create: (context) => GoogleAuthService(),
        ),
        RepositoryProvider<UserRepository>(
          create: (context) => FirestoreUserRepository(),
        ),
        RepositoryProvider<ProductRepository>(
          create: (context) => FirestoreProductRepository(),
        ),
        RepositoryProvider<NotificationRepository>(
          create: (context) => FirestoreNotificationRepository(),
        ),
        RepositoryProvider<OrderRepository>(
          create: (context) => FirestoreOrderRepository(
            productRepository: context.read<ProductRepository>(),
            notificationRepository: context.read<NotificationRepository>(),
            userRepository: context.read<UserRepository>(),
          ),
        ),
        RepositoryProvider<CartRepository>(
          create: (context) => FirestoreCartRepository(),
        ),
        RepositoryProvider<VendorRepository>(
          create: (context) => FirestoreVendorRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authService: context.read<AuthService>(),
              googleAuthService: context.read<GoogleAuthService>(),
              userRepository: context.read<UserRepository>(),
              productRepository: context.read<ProductRepository>(),
            )..add(const AuthCheckRequested()),
          ),
          BlocProvider<ProductBloc>(
            create: (context) =>
                ProductBloc(repository: context.read<ProductRepository>())
                  ..add(const LoadProducts()),
          ),
          BlocProvider<OrderBloc>(
            create: (context) => OrderBloc(
              repository: context.read<OrderRepository>(),
              productRepository: context.read<ProductRepository>(),
            )..add(const LoadOrders()),
          ),
          BlocProvider<CartBloc>(
            create: (context) => CartBloc(
              orderRepository: context.read<OrderRepository>(),
              cartRepository: context.read<CartRepository>(),
              productRepository: context.read<ProductRepository>(),
              userRepository: context.read<UserRepository>(),
            ),
          ),
          BlocProvider<VendorBloc>(
            create: (context) =>
                VendorBloc(repository: context.read<VendorRepository>())
                  ..add(const LoadVendors()),
          ),
          BlocProvider<NotificationBloc>(
            create: (context) => NotificationBloc(
              repository: context.read<NotificationRepository>(),
            ),
          ),
        ],
        child: const _AppWithCartLoader(),
      ),
    );
  }
}

/// Wrapper widget that listens to AuthBloc and loads cart when user is authenticated.
class _AppWithCartLoader extends StatefulWidget {
  const _AppWithCartLoader();

  @override
  State<_AppWithCartLoader> createState() => _AppWithCartLoaderState();
}

class _AppWithCartLoaderState extends State<_AppWithCartLoader> {
  bool _notificationServiceInitialized = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous.userId != current.userId,
      listener: (context, state) {
        // Load cart when user authenticates
        if (state.userId != null) {
          context.read<CartBloc>().add(LoadCart(userId: state.userId));
          // Load notifications when user authenticates
          context.read<NotificationBloc>().add(
            WatchNotifications(userId: state.userId!),
          );

          // Update FCM token for push notifications
          _updateFcmToken(context, state.userId!);
        } else {
          // Show success message if account was deleted
          if (state is AuthAccountDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account deleted successfully.'),
                backgroundColor: Colors.green,
              ),
            );
          }

          // Clear cart locally when user logs out - don't attempt Firestore clear
          // as the user is no longer authenticated
          context.read<CartBloc>().add(
            const ClearCart(clearFromFirestore: false, showNotification: false),
          );
        }
      },
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
        theme: AppTheme.light,
        builder: (context, child) {
          // Initialize in-app notification service once we have a context
          if (!_notificationServiceInitialized) {
            _notificationServiceInitialized = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              InAppNotificationService().init(context);
            });
          } else {
            // Update context on rebuild
            InAppNotificationService().updateContext(context);
          }
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }

  Future<void> _updateFcmToken(BuildContext context, String userId) async {
    try {
      final messaging = FirebaseMessaging.instance;
      // Request permission for push notifications
      await messaging.requestPermission();

      // Get the token for this device
      final token = await messaging.getToken();

      if (token != null && context.mounted) {
        await context.read<UserRepository>().updateFcmToken(userId, token);
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }
}
