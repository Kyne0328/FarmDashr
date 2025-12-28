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
          create: (context) =>
              CartBloc(orderRepository: context.read<OrderBloc>().repository)
                ..add(const LoadCart()),
        ),
        BlocProvider<VendorBloc>(
          create: (context) => VendorBloc()..add(const LoadVendors()),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
        theme: ThemeData(useMaterial3: true),
      ),
    );
  }
}
