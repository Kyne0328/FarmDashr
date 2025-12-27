import 'package:equatable/equatable.dart';
import 'package:farmdashr/data/models/product.dart';

/// Cart item model.
/// Immutable data class following Equatable convention.
class CartItem extends Equatable {
  final Product product;
  final int quantity;

  const CartItem({required this.product, this.quantity = 1});

  @override
  List<Object?> get props => [product, quantity];

  double get total => product.price * quantity;

  String get formattedTotal => '₱${total.toStringAsFixed(2)}';

  /// Creates a copy with updated quantity
  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  /// Returns a new CartItem with quantity incremented by 1
  CartItem increment() => copyWith(quantity: quantity + 1);

  /// Returns a new CartItem with quantity decremented by 1 (minimum 1)
  CartItem decrement() => copyWith(quantity: quantity > 1 ? quantity - 1 : 1);
}
