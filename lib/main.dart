import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'router.dart';
import 'blocs/product/product.dart';
import 'blocs/order/order.dart';
import 'blocs/cart/cart.dart';
import 'blocs/auth/auth.dart';
import 'blocs/vendor/vendor.dart';
import 'blocs/notification/notification.dart';
import 'data/repositories/cart/cart_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc()..add(const AuthCheckRequested()),
        ),
        BlocProvider<ProductBloc>(
          create: (context) => ProductBloc()..add(const LoadProducts()),
        ),
        BlocProvider<OrderBloc>(
          create: (context) => OrderBloc()..add(const LoadOrders()),
        ),
        BlocProvider<CartBloc>(
          create: (context) => CartBloc(
            orderRepository: context.read<OrderBloc>().repository,
            cartRepository: CartRepository(),
          ),
        ),
        BlocProvider<VendorBloc>(
          create: (context) => VendorBloc()..add(const LoadVendors()),
        ),
        BlocProvider<NotificationBloc>(create: (context) => NotificationBloc()),
      ],
      child: const _AppWithCartLoader(),
    );
  }
}

/// Wrapper widget that listens to AuthBloc and loads cart when user is authenticated.
class _AppWithCartLoader extends StatelessWidget {
  const _AppWithCartLoader();

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
        } else {
          // Clear cart when user logs out
          context.read<CartBloc>().add(const ClearCart());
        }
      },
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
        theme: ThemeData(useMaterial3: true),
      ),
    );
  }
}
