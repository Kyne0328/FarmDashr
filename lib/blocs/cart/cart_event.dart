import 'package:equatable/equatable.dart';
import 'package:farmdashr/data/models/product/product.dart';
import 'package:farmdashr/data/models/geo_location.dart';

/// Base class for all cart events.
abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load the cart (initialize or restore from storage).
class LoadCart extends CartEvent {
  final String? userId;

  const LoadCart({this.userId});

  @override
  List<Object?> get props => [userId];
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
  /// Whether to clear cart from Firestore. Set to false during logout to avoid race conditions.
  final bool clearFromFirestore;

  /// Whether to show a notification after clearing.
  final bool showNotification;

  const ClearCart({
    this.clearFromFirestore = true,
    this.showNotification = true,
  });

  @override
  List<Object?> get props => [clearFromFirestore, showNotification];
}

/// Event to refresh product data in the cart (fetch latest prices/stock).
class RefreshCart extends CartEvent {
  const RefreshCart();
}

/// Pickup details for a specific order/vendor
class OrderPickupDetails extends Equatable {
  final String pickupLocation;
  final GeoLocation? pickupLocationCoordinates;
  final String pickupDate;
  final String pickupTime;
  final String? specialInstructions;

  const OrderPickupDetails({
    required this.pickupLocation,
    this.pickupLocationCoordinates,
    required this.pickupDate,
    required this.pickupTime,
    this.specialInstructions,
  });

  @override
  List<Object?> get props => [
    pickupLocation,
    pickupLocationCoordinates,
    pickupDate,
    pickupTime,
    specialInstructions,
  ];
}

/// Event to checkout the cart (convert to order).
class CheckoutCart extends CartEvent {
  final String customerId;
  final String customerName;
  final Map<String, OrderPickupDetails> pickupDetails;

  const CheckoutCart({
    required this.customerId,
    required this.customerName,
    required this.pickupDetails,
  });

  @override
  List<Object?> get props => [customerId, customerName, pickupDetails];
}
