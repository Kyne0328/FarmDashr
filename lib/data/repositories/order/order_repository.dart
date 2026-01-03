import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:farmdashr/data/models/order/order.dart';
import 'package:farmdashr/data/repositories/base_repository.dart';
import 'package:farmdashr/data/repositories/notification/notification_repository.dart';

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
    final batch = FirebaseFirestore.instance.batch();

    // Create the order document
    final docRef = _collection.doc();
    batch.set(docRef, item.toJson());

    // Reduce stock for each item
    if (item.items != null) {
      for (final orderItem in item.items!) {
        final productRef = FirebaseFirestore.instance
            .collection('products')
            .doc(orderItem.productId);
        batch.update(productRef, {
          'currentStock': FieldValue.increment(-orderItem.quantity),
        });
      }
    }

    await batch.commit();
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

  /// Update order status and handle side effects (notifications, stock, revenue)
  Future<Order> updateStatus(String id, OrderStatus newStatus) async {
    final order = await getById(id);
    if (order == null) throw Exception('Order not found');

    final oldStatus = order.status;
    if (oldStatus == newStatus) return order;

    final batch = FirebaseFirestore.instance.batch();

    // Update order status
    batch.update(_collection.doc(id), {'status': newStatus.name});

    // Handle stock restoration if cancelled
    if (newStatus == OrderStatus.cancelled &&
        oldStatus != OrderStatus.cancelled) {
      if (order.items != null) {
        for (final item in order.items!) {
          final productRef = FirebaseFirestore.instance
              .collection('products')
              .doc(item.productId);
          batch.update(productRef, {
            'currentStock': FieldValue.increment(item.quantity),
          });
        }
      }
    }

    // Handle earnings update if completed
    if (newStatus == OrderStatus.completed &&
        oldStatus != OrderStatus.completed) {
      // Update farmer stats
      final farmerRef = FirebaseFirestore.instance
          .collection('users')
          .doc(order.farmerId);

      batch.update(farmerRef, {
        'stats.totalRevenue': FieldValue.increment(order.amount),
        'stats.totalOrders': FieldValue.increment(1),
      });

      // Update product stats (sold and revenue)
      if (order.items != null) {
        for (final item in order.items!) {
          final productRef = FirebaseFirestore.instance
              .collection('products')
              .doc(item.productId);
          batch.update(productRef, {
            'sold': FieldValue.increment(item.quantity),
            'revenue': FieldValue.increment(item.price * item.quantity),
          });
        }
      }
    }

    await batch.commit();

    final result = order.copyWith(status: newStatus);

    // Create notification (async, non-blocking for batch commit)
    _createStatusNotification(result, newStatus);

    return result;
  }

  Future<void> _createStatusNotification(
    Order order,
    OrderStatus newStatus,
  ) async {
    try {
      final notificationRepo = NotificationRepository();
      String title;
      String body;

      switch (newStatus) {
        case OrderStatus.pending:
          title = 'Order Received';
          body = 'Your order from ${order.farmerName} is being processed.';
          break;
        case OrderStatus.ready:
          title = 'Order Ready! 🎉';
          body = 'Your order from ${order.farmerName} is ready for pickup.';
          break;
        case OrderStatus.completed:
          title = 'Order Completed';
          body =
              'Your order from ${order.farmerName} has been completed. Thank you!';
          break;
        case OrderStatus.cancelled:
          title = 'Order Cancelled';
          body = 'Your order from ${order.farmerName} has been cancelled.';
          break;
      }

      await notificationRepo.createOrderNotification(
        userId: order.customerId,
        orderId: order.id,
        title: title,
        body: body,
      );
    } catch (e) {
      debugPrint('Notification failed: $e');
    }
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

  /// Get orders for a specific customer
  /// Note: Sorting is done client-side to avoid composite index requirements
  Future<List<Order>> getByCustomerId(String customerId) async {
    final snapshot = await _collection
        .where('customerId', isEqualTo: customerId)
        .get();
    final orders = snapshot.docs
        .map((doc) => Order.fromJson(doc.data(), doc.id))
        .toList();
    // Sort client-side to avoid composite index requirement
    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  /// Stream of orders for a specific customer
  /// Note: Sorting is done client-side to avoid composite index requirements
  Stream<List<Order>> watchByCustomerId(String customerId) {
    return _collection
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => Order.fromJson(doc.data(), doc.id))
              .toList();
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return orders;
        });
  }
}
