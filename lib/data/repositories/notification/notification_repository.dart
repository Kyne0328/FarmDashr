import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmdashr/data/models/notification/notification.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:farmdashr/core/error/failures.dart';

/// Repository for managing notifications in Firestore
class NotificationRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'notifications';

  NotificationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notificationsRef =>
      _firestore.collection(_collection);

  DatabaseFailure _handleFirebaseException(Object e) {
    if (e is FirebaseException) {
      return DatabaseFailure(
        e.message ?? 'A database error occurred',
        code: e.code,
      );
    }
    return DatabaseFailure(e.toString());
  }

  /// Get all notifications for a user
  Future<List<AppNotification>> getByUserId(
    String userId, {
    UserType? targetUserType,
  }) async {
    try {
      var query = _notificationsRef.where('userId', isEqualTo: userId);

      if (targetUserType != null) {
        query = query.where('targetUserType', isEqualTo: targetUserType.name);
      }

      final snapshot = await query.get();

      final notifications = snapshot.docs
          .map((doc) => AppNotification.fromJson(doc.data(), doc.id))
          .toList();

      // Sort client-side to avoid composite index requirement
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  /// Watch notifications for a user in real-time
  Stream<List<AppNotification>> watchByUserId(
    String userId, {
    UserType? targetUserType,
  }) {
    var query = _notificationsRef.where('userId', isEqualTo: userId);

    if (targetUserType != null) {
      query = query.where('targetUserType', isEqualTo: targetUserType.name);
    }

    return query.snapshots().map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => AppNotification.fromJson(doc.data(), doc.id))
          .toList();

      // Sort client-side to avoid composite index requirement
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    });
  }

  /// Get unread notification count for a user
  Future<int> getUnreadCount(String userId, {UserType? targetUserType}) async {
    try {
      var query = _notificationsRef
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false);

      if (targetUserType != null) {
        query = query.where('targetUserType', isEqualTo: targetUserType.name);
      }

      final snapshot = await query.count().get();

      return snapshot.count ?? 0;
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  /// Watch unread count in real-time
  Stream<int> watchUnreadCount(String userId, {UserType? targetUserType}) {
    var query = _notificationsRef
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false);

    if (targetUserType != null) {
      query = query.where('targetUserType', isEqualTo: targetUserType.name);
    }

    return query.snapshots().map((snapshot) => snapshot.docs.length);
  }

  /// Create a new notification
  Future<AppNotification> create(AppNotification notification) async {
    try {
      final data = notification.toJson();
      final docRef = await _notificationsRef.add(data);
      return notification.copyWith(id: docRef.id);
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String id) async {
    try {
      await _notificationsRef.doc(id).update({'isRead': true});
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId, {UserType? targetUserType}) async {
    try {
      final batch = _firestore.batch();
      var query = _notificationsRef
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false);

      if (targetUserType != null) {
        query = query.where('targetUserType', isEqualTo: targetUserType.name);
      }

      final snapshot = await query.get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  /// Delete a notification
  Future<void> delete(String id) async {
    try {
      await _notificationsRef.doc(id).delete();
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  /// Delete all notifications for a user
  Future<void> deleteAll(String userId, {UserType? targetUserType}) async {
    try {
      final batch = _firestore.batch();
      var query = _notificationsRef.where('userId', isEqualTo: userId);

      if (targetUserType != null) {
        query = query.where('targetUserType', isEqualTo: targetUserType.name);
      }

      final snapshot = await query.get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  /// Create an order update notification
  Future<AppNotification> createOrderNotification({
    required String userId,
    required String orderId,
    required String title,
    required String body,
    UserType? targetUserType,
    bool shouldPush = true,
  }) async {
    final notification = AppNotification(
      id: '',
      userId: userId,
      title: title,
      body: body,
      type: NotificationType.orderUpdate,
      orderId: orderId,
      createdAt: DateTime.now(),
      targetUserType: targetUserType,
      shouldPush: shouldPush,
    );

    return create(notification);
  }
}
