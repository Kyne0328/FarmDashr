import 'package:equatable/equatable.dart';
import 'package:farmdashr/data/models/cart/cart_item.dart';

/// Base class for all cart states.
abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

/// Initial state before the cart is loaded.
class CartInitial extends CartState {
  const CartInitial();
}

/// State while the cart is being loaded.
class CartLoading extends CartState {
  const CartLoading();
}

/// State when the cart is loaded and ready.
class CartLoaded extends CartState {
  final List<CartItem> items;

  const CartLoaded({this.items = const []});

  /// Total number of items in the cart.
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Total number of unique products in the cart.
  int get uniqueItemCount => items.length;

  /// Total price of all items in the cart.
  double get totalPrice => items.fold(0.0, (sum, item) => sum + item.total);

  /// Formatted total price string.
  String get formattedTotal => '₱${totalPrice.toStringAsFixed(2)}';

  /// Whether the cart is empty.
  bool get isEmpty => items.isEmpty;

  /// Whether the cart has items.
  bool get isNotEmpty => items.isNotEmpty;

  /// Get a cart item by product ID.
  CartItem? getItem(String productId) {
    try {
      return items.firstWhere((item) => item.product.id == productId);
    } catch (_) {
      return null;
    }
  }

  /// Check if a product is in the cart.
  bool containsProduct(String productId) {
    return items.any((item) => item.product.id == productId);
  }

  @override
  List<Object?> get props => [items];

  /// Create a copy with updated values.
  CartLoaded copyWith({List<CartItem>? items}) {
    return CartLoaded(items: items ?? this.items);
  }
}

/// State when an error occurs with the cart.
class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State when a cart operation (e.g., checkout) is successful.
class CartOperationSuccess extends CartState {
  final String message;
  final List<CartItem> items;

  const CartOperationSuccess({required this.message, this.items = const []});

  @override
  List<Object?> get props => [message, items];
}

/// State when checkout is successful.
class CartCheckoutSuccess extends CartState {
  final String orderId;
  final String message;

  const CartCheckoutSuccess({
    required this.orderId,
    this.message = 'Order placed successfully!',
  });

  @override
  List<Object?> get props => [orderId, message];
}
