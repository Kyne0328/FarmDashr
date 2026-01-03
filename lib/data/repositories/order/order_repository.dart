import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:farmdashr/data/models/order/order.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:farmdashr/data/repositories/base_repository.dart';
import 'package:farmdashr/data/repositories/notification/notification_repository.dart';
import 'package:farmdashr/data/repositories/product/product_repository.dart';
import 'package:farmdashr/data/repositories/auth/user_repository.dart';
import 'package:farmdashr/core/error/failures.dart';

/// Repository for managing Order data in Firestore.
class OrderRepository implements BaseRepository<Order, String> {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('orders');

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
  Future<List<Order>> getAll() async {
    try {
      final snapshot = await _collection
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Order.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  @override
  Future<Order?> getById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (doc.exists && doc.data() != null) {
        return Order.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  @override
  Future<Order> create(Order item) async {
    try {
      final docRef = await _collection.add(item.toJson());
      final newOrder = item.copyWith(id: docRef.id);

      // Decrement stock immediately on creation
      if (newOrder.items != null && newOrder.items!.isNotEmpty) {
        try {
          final productRepo = ProductRepository();
          await productRepo.decrementStock(newOrder.items!);
        } catch (e) {
          // Log or handle stock decrement failure
          debugPrint('Error decrementing stock for order ${newOrder.id}: $e');
        }
      }

      // Notify farmer and customer about new order
      try {
        final notificationRepo = NotificationRepository();

        // Farmer notification
        await notificationRepo.createOrderNotification(
          userId: newOrder.farmerId,
          orderId: newOrder.id,
          title: 'New Order Received! 🆕',
          body: 'You have a new order from ${newOrder.customerName}.',
          targetUserType: UserType.farmer,
        );

        // Customer notification (New)
        await notificationRepo.createOrderNotification(
          userId: newOrder.customerId,
          orderId: newOrder.id,
          title: 'Order Placed! 🛒',
          body:
              'Your order with ${newOrder.farmerName} has been placed successfully.',
          targetUserType: UserType.customer,
        );
      } catch (e) {
        // Log notification failures for debugging
        debugPrint('Notification failed: $e');
      }

      return newOrder;
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  @override
  Future<Order> update(Order item) async {
    try {
      await _collection.doc(item.id).update(item.toJson());
      return item;
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  @override
  Future<bool> delete(String id) async {
    try {
      await _collection.doc(id).delete();
      return true;
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  /// Get orders by status
  Future<List<Order>> getByStatus(OrderStatus status) async {
    try {
      final snapshot = await _collection
          .where('status', isEqualTo: status.name)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Order.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  /// Get orders for a specific farmer
  /// Note: Sorting is done client-side to avoid composite index requirements
  Future<List<Order>> getByFarmerId(String farmerId) async {
    try {
      final snapshot = await _collection
          .where('farmerId', isEqualTo: farmerId)
          .get();
      final orders = snapshot.docs
          .map((doc) => Order.fromJson(doc.data(), doc.id))
          .toList();
      // Sort client-side to avoid composite index requirement
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    } catch (e) {
      throw _handleFirebaseException(e);
    }
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

  /// Update order status and notify customer
  Future<Order> updateStatus(String id, OrderStatus newStatus) async {
    try {
      final order = await getById(id);
      if (order == null) {
        throw const DatabaseFailure('Order not found', code: 'not-found');
      }

      if (order.status == newStatus) return order;

      final updated = order.copyWith(status: newStatus);
      final result = await update(updated);

      // Handle stock adjustments based on status change
      if (order.items != null && order.items!.isNotEmpty) {
        final productRepo = ProductRepository();

        // Increment stock back if order is cancelled
        if (newStatus == OrderStatus.cancelled &&
            order.status != OrderStatus.cancelled) {
          try {
            await productRepo.incrementStock(order.items!);
          } catch (e) {
            debugPrint('Error incrementing stock for order $id: $e');
          }
        }

        // Decrement stock if order is un-cancelled (transitioning FROM cancelled to another status)
        if (order.status == OrderStatus.cancelled &&
            newStatus != OrderStatus.cancelled) {
          try {
            await productRepo.decrementStock(order.items!);
          } catch (e) {
            debugPrint(
              'Error decrementing stock for un-cancelled order $id: $e',
            );
          }
        }
      }

      // Create notification for customer about status change
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
            // Update stats
            _calculateAndSaveFarmerStats(order.farmerId);
            break;
          case OrderStatus.cancelled:
            title = 'Order Cancelled';
            body = 'Your order from ${order.farmerName} has been cancelled.';
            break;
        }

        await notificationRepo.createOrderNotification(
          userId: order.customerId,
          orderId: id,
          title: title,
          body: body,
          targetUserType: UserType.customer,
        );
      } catch (e) {
        // Don't fail the status update if notification fails
        debugPrint('Notification failed for status update: $e');
      }

      return result;
    } catch (e) {
      if (e is Failure) rethrow;
      throw _handleFirebaseException(e);
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
    try {
      final snapshot = await _collection
          .where('customerId', isEqualTo: customerId)
          .get();
      final orders = snapshot.docs
          .map((doc) => Order.fromJson(doc.data(), doc.id))
          .toList();
      // Sort client-side to avoid composite index requirement
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    } catch (e) {
      throw _handleFirebaseException(e);
    }
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

  /// Calculate and save farmer stats
  Future<void> _calculateAndSaveFarmerStats(String farmerId) async {
    try {
      final orders = await getByFarmerId(farmerId);
      final completedOrders = orders
          .where((o) => o.status == OrderStatus.completed)
          .toList();

      double totalRevenue = 0;
      int productsSold = 0;
      final uniqueCustomers = <String>{};

      for (final order in completedOrders) {
        totalRevenue += order.amount;
        if (order.items != null) {
          for (final item in order.items!) {
            productsSold += item.quantity;
          }
        }
        uniqueCustomers.add(order.customerId);
      }

      final stats = UserStats(
        totalRevenue: totalRevenue,
        revenueChange: 0, // Requires historical data
        productsSold: productsSold,
        productsSoldChange: 0, // Requires historical data
        totalOrders: completedOrders.length,
        totalCustomers: uniqueCustomers.length,
      );

      final userRepo = UserRepository();
      await userRepo.updateStats(farmerId, stats);
    } catch (e) {
      debugPrint('Error updating farmer stats: $e');
    }
  }
}
