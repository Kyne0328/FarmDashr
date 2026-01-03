import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmdashr/data/models/notification/notification.dart';

/// Repository for managing notifications in Firestore
class NotificationRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'notifications';

  NotificationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notificationsRef =>
      _firestore.collection(_collection);

  /// Get all notifications for a user
  Future<List<AppNotification>> getByUserId(String userId) async {
    final snapshot = await _notificationsRef
        .where('userId', isEqualTo: userId)
        .get();

    final notifications = snapshot.docs
        .map((doc) => AppNotification.fromJson(doc.data(), doc.id))
        .toList();

    // Sort client-side to avoid composite index requirement
    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notifications;
  }

  /// Watch notifications for a user in real-time
  Stream<List<AppNotification>> watchByUserId(String userId) {
    return _notificationsRef.where('userId', isEqualTo: userId).snapshots().map(
      (snapshot) {
        final notifications = snapshot.docs
            .map((doc) => AppNotification.fromJson(doc.data(), doc.id))
            .toList();

        // Sort client-side to avoid composite index requirement
        notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return notifications;
      },
    );
  }

  /// Get unread notification count for a user
  Future<int> getUnreadCount(String userId) async {
    final snapshot = await _notificationsRef
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Watch unread count in real-time
  Stream<int> watchUnreadCount(String userId) {
    return _notificationsRef
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Create a new notification
  Future<AppNotification> create(AppNotification notification) async {
    final docRef = await _notificationsRef.add(notification.toJson());
    return notification.copyWith(id: docRef.id);
  }

  /// Mark a notification as read
  Future<void> markAsRead(String id) async {
    await _notificationsRef.doc(id).update({'isRead': true});
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    final snapshot = await _notificationsRef
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  /// Delete a notification
  Future<void> delete(String id) async {
    await _notificationsRef.doc(id).delete();
  }

  /// Create an order update notification
  Future<AppNotification> createOrderNotification({
    required String userId,
    required String orderId,
    required String title,
    required String body,
  }) async {
    final notification = AppNotification(
      id: '',
      userId: userId,
      title: title,
      body: body,
      type: NotificationType.orderUpdate,
      orderId: orderId,
      createdAt: DateTime.now(),
    );

    return create(notification);
  }
}
