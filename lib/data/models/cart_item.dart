import 'package:farmdashr/data/models/product.dart';

/// Cart item model.
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;

  String get formattedTotal => '\$${total.toStringAsFixed(2)}';

  void increment() {
    quantity++;
  }

  void decrement() {
    if (quantity > 1) {
      quantity--;
    }
  }
}
