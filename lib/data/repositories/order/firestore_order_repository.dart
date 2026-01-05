import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:farmdashr/data/models/order/order.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:farmdashr/core/services/push_notification_service.dart';
import 'package:farmdashr/core/error/failures.dart';
import 'package:farmdashr/data/repositories/repositories.dart';

/// Firestore implementation of Order repository.
class FirestoreOrderRepository implements OrderRepository {
  final FirebaseFirestore _firestore;
  final ProductRepository _productRepository;
  final NotificationRepository _notificationRepository;
  final UserRepository _userRepository;

  FirestoreOrderRepository({
    FirebaseFirestore? firestore,
    required ProductRepository productRepository,
    required NotificationRepository notificationRepository,
    required UserRepository userRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _productRepository = productRepository,
       _notificationRepository = notificationRepository,
       _userRepository = userRepository;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('orders');

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
          await _productRepository.decrementStock(newOrder.items!);
        } catch (e) {
          debugPrint('Error decrementing stock for order ${newOrder.id}: $e');
        }
      }

      // Notify farmer and customer about new order
      try {
        // Farmer notification
        final farmerPush = await _shouldPushForUser(
          newOrder.farmerId,
          isNewOrderCallback: true,
        );
        await _notificationRepository.createOrderNotification(
          userId: newOrder.farmerId,
          orderId: newOrder.id,
          title: 'New Order Received! 🆕',
          body: 'You have a new order from ${newOrder.customerName}.',
          targetUserType: UserType.farmer,
          shouldPush: farmerPush,
        );

        // Customer notification
        final customerPush = await _shouldPushForUser(newOrder.customerId);
        await _notificationRepository.createOrderNotification(
          userId: newOrder.customerId,
          orderId: newOrder.id,
          title: 'Order Placed! 🛒',
          body:
              'Your order with ${newOrder.farmerName} has been placed successfully.',
          targetUserType: UserType.customer,
          shouldPush: customerPush,
        );

        // Send actual push alerts
        _sendPushNotification(
          newOrder.farmerId,
          'New Order Received! 🆕',
          'You have a new order from ${newOrder.customerName}.',
          isNewOrderCallback: true,
          orderId: newOrder.id,
        );
        _sendPushNotification(
          newOrder.customerId,
          'Order Placed! 🛒',
          'Your order with ${newOrder.farmerName} has been placed successfully.',
          orderId: newOrder.id,
        );
      } catch (e) {
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

  @override
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

  @override
  Future<List<Order>> getByFarmerId(String farmerId) async {
    try {
      final snapshot = await _collection
          .where('farmerId', isEqualTo: farmerId)
          .get();
      final orders = snapshot.docs
          .map((doc) => Order.fromJson(doc.data(), doc.id))
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  @override
  Future<int> getPendingCount() async {
    final pending = await getByStatus(OrderStatus.pending);
    return pending.length;
  }

  @override
  Future<int> getReadyCount() async {
    final ready = await getByStatus(OrderStatus.ready);
    return ready.length;
  }

  @override
  Future<Order> updateStatus(String id, OrderStatus newStatus) async {
    try {
      final orderDocRef = _collection.doc(id);

      final Order updatedOrder = await _firestore.runTransaction((
        transaction,
      ) async {
        final doc = await transaction.get(orderDocRef);
        if (!doc.exists) {
          throw const DatabaseFailure('Order not found', code: 'not-found');
        }

        final order = Order.fromJson(doc.data()!, doc.id);
        if (order.status == newStatus) return order;

        final updated = order.copyWith(status: newStatus);

        // Update order status
        transaction.update(orderDocRef, updated.toJson());

        // Handle stock adjustments based on status change within the transaction
        if (order.items != null && order.items!.isNotEmpty) {
          final productsCollection = _firestore.collection('products');

          // If cancelling an order, return stock
          if (newStatus == OrderStatus.cancelled &&
              order.status != OrderStatus.cancelled) {
            for (final item in order.items!) {
              if (item.productId.isEmpty) continue;
              final productRef = productsCollection.doc(item.productId);
              transaction.update(productRef, {
                'currentStock': FieldValue.increment(item.quantity),
                'sold': FieldValue.increment(-item.quantity),
                'revenue': FieldValue.increment(-(item.quantity * item.price)),
              });
            }
          }

          // If un-cancelling an order, re-decrement stock
          if (order.status == OrderStatus.cancelled &&
              newStatus != OrderStatus.cancelled) {
            for (final item in order.items!) {
              if (item.productId.isEmpty) continue;
              final productRef = productsCollection.doc(item.productId);
              transaction.update(productRef, {
                'currentStock': FieldValue.increment(-item.quantity),
                'sold': FieldValue.increment(item.quantity),
                'revenue': FieldValue.increment(item.quantity * item.price),
              });
            }
          }
        }

        // Handle Realized Revenue (Sold & Revenue updates)
        if (order.items != null && order.items!.isNotEmpty) {
          final productsCollection = _firestore.collection('products');

          // 1. Order becomes COMPLETED: Crediting Revenue
          if (newStatus == OrderStatus.completed &&
              order.status != OrderStatus.completed) {
            for (final item in order.items!) {
              if (item.productId.isEmpty) continue;
              final productRef = productsCollection.doc(item.productId);
              transaction.update(productRef, {
                'sold': FieldValue.increment(item.quantity),
                'revenue': FieldValue.increment(item.quantity * item.price),
              });
            }
          }

          // 2. Order was COMPLETED but changed (e.g. Refund/Mistake): Debiting Revenue
          if (order.status == OrderStatus.completed &&
              newStatus != OrderStatus.completed) {
            for (final item in order.items!) {
              if (item.productId.isEmpty) continue;
              final productRef = productsCollection.doc(item.productId);
              transaction.update(productRef, {
                'sold': FieldValue.increment(-item.quantity),
                'revenue': FieldValue.increment(-(item.quantity * item.price)),
              });
            }
          }
        }

        return updated;
      });

      // Send notification after successful transaction
      _notifyStatusChange(updatedOrder, newStatus);

      return updatedOrder;
    } catch (e) {
      if (e is Failure) rethrow;
      throw _handleFirebaseException(e);
    }
  }

  Future<void> _notifyStatusChange(Order order, OrderStatus newStatus) async {
    try {
      String title;
      String body;

      switch (newStatus) {
        case OrderStatus.preparing:
          title = 'Order Preparing';
          body = 'Your order from ${order.farmerName} is now being prepared.';
          break;
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

      final customerPush = await _shouldPushForUser(order.customerId);
      await _notificationRepository.createOrderNotification(
        userId: order.customerId,
        orderId: order.id,
        title: title,
        body: body,
        targetUserType: UserType.customer,
        shouldPush: customerPush,
      );

      _sendPushNotification(order.customerId, title, body, orderId: order.id);
    } catch (e) {
      debugPrint('Notification failed for status update: $e');
    }
  }

  @override
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

  @override
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

  @override
  Future<List<Order>> getByCustomerId(String customerId) async {
    try {
      final snapshot = await _collection
          .where('customerId', isEqualTo: customerId)
          .get();
      final orders = snapshot.docs
          .map((doc) => Order.fromJson(doc.data(), doc.id))
          .toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  @override
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

  Future<bool> _shouldPushForUser(
    String userId, {
    bool isNewOrderCallback = false,
  }) async {
    try {
      final profile = await _userRepository.getById(userId);
      if (profile == null) return true;

      final prefs = profile.notificationPreferences;
      if (!prefs.pushEnabled) return false;

      if (profile.isFarmer) {
        if (isNewOrderCallback) {
          return prefs.newOrders;
        }
        return true;
      } else {
        return prefs.orderUpdates;
      }
    } catch (e) {
      debugPrint('Error checking notification prefs: $e');
      return true;
    }
  }

  Future<void> _sendPushNotification(
    String userId,
    String title,
    String body, {
    bool isNewOrderCallback = false,
    String? orderId,
  }) async {
    try {
      final profile = await _userRepository.getById(userId);
      if (profile == null || profile.fcmToken == null) return;

      final prefs = profile.notificationPreferences;
      if (!prefs.pushEnabled) return;

      bool shouldPush = true;
      if (profile.isFarmer) {
        shouldPush = isNewOrderCallback ? prefs.newOrders : true;
      } else {
        shouldPush = prefs.orderUpdates;
      }

      if (shouldPush) {
        await PushNotificationService.sendNotification(
          token: profile.fcmToken!,
          title: title,
          body: body,
          payload: {
            if (orderId != null) 'orderId': orderId,
            'type': isNewOrderCallback ? 'newOrder' : 'statusUpdate',
          },
        );
      }
    } catch (e) {
      debugPrint('Error sending push alert: $e');
    }
  }
}
