import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmdashr/data/models/cart/cart_item.dart';

/// Repository for managing user cart data in Firestore.
/// Each user has a single cart document at `carts/{userId}`.
class CartRepository {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('carts');

  /// Get cart items for a specific user.
  Future<List<CartItem>> getCart(String userId) async {
    try {
      final doc = await _collection.doc(userId).get();
      if (!doc.exists || doc.data() == null) {
        return [];
      }

      final data = doc.data()!;
      final items = data['items'] as List<dynamic>? ?? [];

      return items.map((item) {
        final map = item as Map<String, dynamic>;
        return CartItem.fromJson(map);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Save cart items for a specific user.
  Future<void> saveCart(String userId, List<CartItem> items) async {
    try {
      await _collection.doc(userId).set({
        'items': items.map((item) => item.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Clear cart for a specific user.
  Future<void> clearCart(String userId) async {
    try {
      await _collection.doc(userId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Stream of cart items for real-time updates.
  Stream<List<CartItem>> watchCart(String userId) {
    return _collection.doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return <CartItem>[];
      }

      final data = snapshot.data()!;
      final items = data['items'] as List<dynamic>? ?? [];

      return items.map((item) {
        final map = item as Map<String, dynamic>;
        return CartItem.fromJson(map);
      }).toList();
    });
  }
}
