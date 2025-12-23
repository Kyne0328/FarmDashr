import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'router.dart';
import 'blocs/product/product.dart';
import 'blocs/order/order.dart';
import 'blocs/cart/cart.dart';

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
        BlocProvider<ProductBloc>(
          create: (context) => ProductBloc()..add(const LoadProducts()),
        ),
        BlocProvider<OrderBloc>(
          create: (context) => OrderBloc()..add(const LoadOrders()),
        ),
        BlocProvider<CartBloc>(
          create: (context) => CartBloc()..add(const LoadCart()),
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
