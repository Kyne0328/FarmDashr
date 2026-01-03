import 'package:equatable/equatable.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';

/// Base class for notification events
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

/// Load notifications for a user
class LoadNotifications extends NotificationEvent {
  final String userId;
  final UserType? userType;

  const LoadNotifications({required this.userId, this.userType});

  @override
  List<Object?> get props => [userId, userType];
}

/// Watch notifications for a user in real-time
class WatchNotifications extends NotificationEvent {
  final String userId;
  final UserType? userType;

  const WatchNotifications({required this.userId, this.userType});

  @override
  List<Object?> get props => [userId, userType];
}

/// Internal event when notifications are received from stream
class NotificationsReceived extends NotificationEvent {
  final List notifications;
  final int unreadCount;

  const NotificationsReceived({
    required this.notifications,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [notifications, unreadCount];
}

/// Mark a single notification as read
class MarkNotificationAsRead extends NotificationEvent {
  final String notificationId;

  const MarkNotificationAsRead({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

/// Mark all notifications as read for a user
class MarkAllNotificationsAsRead extends NotificationEvent {
  final String userId;
  final UserType? userType;

  const MarkAllNotificationsAsRead({required this.userId, this.userType});

  @override
  List<Object?> get props => [userId, userType];
}

/// Delete a single notification
class DeleteNotification extends NotificationEvent {
  final String notificationId;

  const DeleteNotification({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

/// Delete all notifications for a user (Clear All)
class ClearAllNotifications extends NotificationEvent {
  final String userId;
  final UserType? userType;

  const ClearAllNotifications({required this.userId, this.userType});

  @override
  List<Object?> get props => [userId, userType];
}

/// Event when an error occurs in the notification stream
class NotificationErrorOccurred extends NotificationEvent {
  final String message;

  const NotificationErrorOccurred(this.message);

  @override
  List<Object?> get props => [message];
}
