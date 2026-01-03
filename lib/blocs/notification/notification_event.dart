import 'package:equatable/equatable.dart';

/// Base class for notification events
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

/// Load notifications for a user
class LoadNotifications extends NotificationEvent {
  final String userId;

  const LoadNotifications({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Watch notifications for a user in real-time
class WatchNotifications extends NotificationEvent {
  final String userId;

  const WatchNotifications({required this.userId});

  @override
  List<Object?> get props => [userId];
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

  const MarkAllNotificationsAsRead({required this.userId});

  @override
  List<Object?> get props => [userId];
}
