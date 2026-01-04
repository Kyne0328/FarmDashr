import 'package:farmdashr/data/models/notification/notification.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';

/// Repository interface for managing notifications.
abstract class NotificationRepository {
  /// Get all notifications for a user
  Future<List<AppNotification>> getByUserId(
    String userId, {
    UserType? targetUserType,
  });

  /// Watch notifications for a user in real-time
  Stream<List<AppNotification>> watchByUserId(
    String userId, {
    UserType? targetUserType,
  });

  /// Get unread notification count for a user
  Future<int> getUnreadCount(String userId, {UserType? targetUserType});

  /// Watch unread count in real-time
  Stream<int> watchUnreadCount(String userId, {UserType? targetUserType});

  /// Create a new notification
  Future<AppNotification> create(AppNotification notification);

  /// Mark a notification as read
  Future<void> markAsRead(String id);

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId, {UserType? targetUserType});

  /// Delete a notification
  Future<void> delete(String id);

  /// Delete all notifications for a user
  Future<void> deleteAll(String userId, {UserType? targetUserType});

  /// Create an order update notification
  Future<AppNotification> createOrderNotification({
    required String userId,
    required String orderId,
    required String title,
    required String body,
    UserType? targetUserType,
    bool shouldPush,
  });
}
