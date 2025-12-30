import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:farmdashr/data/models/order.dart';
import 'package:farmdashr/data/repositories/base_repository.dart';

/// Repository for managing Order data in Firestore.
class OrderRepository implements BaseRepository<Order, String> {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('orders');

  @override
  Future<List<Order>> getAll() async {
    final snapshot = await _collection
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Order.fromJson(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<Order?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (doc.exists && doc.data() != null) {
      return Order.fromJson(doc.data()!, doc.id);
    }
    return null;
  }

  @override
  Future<Order> create(Order item) async {
    final docRef = await _collection.add(item.toJson());
    return item.copyWith(id: docRef.id);
  }

  @override
  Future<Order> update(Order item) async {
    await _collection.doc(item.id).update(item.toJson());
    return item;
  }

  @override
  Future<bool> delete(String id) async {
    try {
      await _collection.doc(id).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get orders by status
  Future<List<Order>> getByStatus(OrderStatus status) async {
    final snapshot = await _collection
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Order.fromJson(doc.data(), doc.id))
        .toList();
  }

  /// Get orders for a specific farmer
  /// Note: Sorting is done client-side to avoid composite index requirements
  Future<List<Order>> getByFarmerId(String farmerId) async {
    final snapshot = await _collection
        .where('farmerId', isEqualTo: farmerId)
        .get();
    final orders = snapshot.docs
        .map((doc) => Order.fromJson(doc.data(), doc.id))
        .toList();
    // Sort client-side to avoid composite index requirement
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  /// Get pending orders count
  Future<int> getPendingCount() async {
    final pending = await getByStatus(OrderStatus.pending);
    return pending.length;
  }

  /// Get ready orders count
  Future<int> getReadyCount() async {
    final ready = await getByStatus(OrderStatus.ready);
    return ready.length;
  }

  /// Update order status
  Future<Order> updateStatus(String id, OrderStatus newStatus) async {
    final order = await getById(id);
    if (order != null) {
      final updated = order.copyWith(status: newStatus);
      return update(updated);
    }
    throw Exception('Order not found');
  }

  /// Stream of all orders (real-time updates)
  Stream<List<Order>> watchAll() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Order.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Stream of orders for a specific farmer
  /// Note: Sorting is done client-side to avoid composite index requirements
  Stream<List<Order>> watchByFarmerId(String farmerId) {
    return _collection.where('farmerId', isEqualTo: farmerId).snapshots().map((
      snapshot,
    ) {
      final orders = snapshot.docs
          .map((doc) => Order.fromJson(doc.data(), doc.id))
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }
}
