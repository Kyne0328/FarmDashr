import 'package:farmdashr/data/models/cart/cart_item.dart';

/// Repository interface for managing user cart data.
abstract class CartRepository {
  /// Get cart items for a specific user.
  Future<List<CartItem>> getCart(String userId);

  /// Save cart items for a specific user.
  Future<void> saveCart(String userId, List<CartItem> items);

  /// Clear cart for a specific user.
  Future<void> clearCart(String userId);

  /// Stream of cart items for real-time updates.
  Stream<List<CartItem>> watchCart(String userId);
}
