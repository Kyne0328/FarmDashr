import 'package:equatable/equatable.dart';
import 'package:farmdashr/data/models/product.dart';

/// Base class for all cart events.
abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load the cart (initialize or restore from storage).
class LoadCart extends CartEvent {
  const LoadCart();
}

/// Event to add a product to the cart.
class AddToCart extends CartEvent {
  final Product product;
  final int quantity;

  const AddToCart(this.product, {this.quantity = 1});

  @override
  List<Object?> get props => [product, quantity];
}

/// Event to remove a product from the cart.
class RemoveFromCart extends CartEvent {
  final String productId;

  const RemoveFromCart(this.productId);

  @override
  List<Object?> get props => [productId];
}

/// Event to update the quantity of a cart item.
class UpdateCartItemQuantity extends CartEvent {
  final String productId;
  final int quantity;

  const UpdateCartItemQuantity(this.productId, this.quantity);

  @override
  List<Object?> get props => [productId, quantity];
}

/// Event to increment the quantity of a cart item by 1.
class IncrementCartItem extends CartEvent {
  final String productId;

  const IncrementCartItem(this.productId);

  @override
  List<Object?> get props => [productId];
}

/// Event to decrement the quantity of a cart item by 1.
class DecrementCartItem extends CartEvent {
  final String productId;

  const DecrementCartItem(this.productId);

  @override
  List<Object?> get props => [productId];
}

/// Event to clear all items from the cart.
class ClearCart extends CartEvent {
  const ClearCart();
}

/// Event to checkout the cart (convert to order).
class CheckoutCart extends CartEvent {
  final String customerId;
  final String customerName;
  final String farmerId;
  final String farmerName;
  final String pickupLocation;
  final String pickupDate;
  final String pickupTime;
  final String? specialInstructions;

  const CheckoutCart({
    required this.customerId,
    required this.customerName,
    required this.farmerId,
    required this.farmerName,
    required this.pickupLocation,
    required this.pickupDate,
    required this.pickupTime,
    this.specialInstructions,
  });

  @override
  List<Object?> get props => [
    customerId,
    customerName,
    farmerId,
    farmerName,
    pickupLocation,
    pickupDate,
    pickupTime,
    specialInstructions,
  ];
}
