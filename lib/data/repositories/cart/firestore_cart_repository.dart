import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmdashr/data/models/cart/cart_item.dart';
import 'package:farmdashr/core/error/failures.dart';
import 'cart_repository.dart';

/// Firestore implementation of user cart repository.
class FirestoreCartRepository implements CartRepository {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('carts');

  DatabaseFailure _handleFirebaseException(Object e) {
    if (e is FirebaseException) {
      return DatabaseFailure(
        e.message ?? 'A database error occurred',
        code: e.code,
      );
    }
    return DatabaseFailure(e.toString());
  }

  @override
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
      throw _handleFirebaseException(e);
    }
  }

  @override
  Future<void> saveCart(String userId, List<CartItem> items) async {
    try {
      await _collection.doc(userId).set({
        'items': items.map((item) => item.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  @override
  Future<void> clearCart(String userId) async {
    try {
      await _collection.doc(userId).delete();
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  @override
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
