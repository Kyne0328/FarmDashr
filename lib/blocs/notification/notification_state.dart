import 'package:equatable/equatable.dart';
import 'package:farmdashr/data/models/notification.dart';

/// Base class for notification states
abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

/// Initial state before notifications are loaded
class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

/// Loading state while fetching notifications
class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

/// State when notifications are successfully loaded
class NotificationLoaded extends NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;

  const NotificationLoaded({required this.notifications, this.unreadCount = 0});

  @override
  List<Object?> get props => [notifications, unreadCount];

  /// Create a copy with updated fields
  NotificationLoaded copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

/// Error state when something goes wrong
class NotificationError extends NotificationState {
  final String message;

  const NotificationError(this.message);

  @override
  List<Object?> get props => [message];
}

/// State after successful operation (mark as read, etc.)
class NotificationOperationSuccess extends NotificationState {
  final String message;

  const NotificationOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
