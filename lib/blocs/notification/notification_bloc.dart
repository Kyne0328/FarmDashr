import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:farmdashr/data/models/notification/notification.dart';
import 'package:farmdashr/data/repositories/notification/notification_repository.dart';
import 'package:farmdashr/blocs/notification/notification_event.dart';
import 'package:farmdashr/blocs/notification/notification_state.dart';

/// BLoC for managing notification state
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repository;
  NotificationRepository get repository => _repository;

  StreamSubscription? _notificationsSubscription;
  StreamSubscription? _unreadCountSubscription;

  NotificationBloc({NotificationRepository? repository})
    : _repository = repository ?? NotificationRepository(),
      super(const NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<WatchNotifications>(_onWatchNotifications);
    on<NotificationsReceived>(_onNotificationsReceived);
    on<MarkNotificationAsRead>(_onMarkAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllAsRead);
    on<NotificationErrorOccurred>(_onNotificationErrorOccurred);
  }

  @override
  Future<void> close() {
    _notificationsSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    return super.close();
  }

  /// Handle LoadNotifications event
  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(const NotificationLoading());
    try {
      final notifications = await _repository.getByUserId(event.userId);
      final unreadCount = await _repository.getUnreadCount(event.userId);
      emit(
        NotificationLoaded(
          notifications: notifications,
          unreadCount: unreadCount,
        ),
      );
    } catch (e) {
      emit(NotificationError('Failed to load notifications: ${e.toString()}'));
    }
  }

  /// Handle WatchNotifications event - subscribes to real-time updates
  Future<void> _onWatchNotifications(
    WatchNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(const NotificationLoading());
    await _notificationsSubscription?.cancel();
    await _unreadCountSubscription?.cancel();

    // Watch notifications stream
    _notificationsSubscription = _repository
        .watchByUserId(event.userId)
        .listen(
          (notifications) {
            final unreadCount = notifications.where((n) => !n.isRead).length;
            add(
              NotificationsReceived(
                notifications: notifications,
                unreadCount: unreadCount,
              ),
            );
          },
          onError: (error) {
            add(NotificationErrorOccurred(error.toString()));
          },
        );
  }

  /// Handle NotificationsReceived event
  void _onNotificationsReceived(
    NotificationsReceived event,
    Emitter<NotificationState> emit,
  ) {
    final notifications = event.notifications.cast<AppNotification>();
    emit(
      NotificationLoaded(
        notifications: notifications,
        unreadCount: event.unreadCount,
      ),
    );
  }

  /// Handle MarkNotificationAsRead event
  Future<void> _onMarkAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repository.markAsRead(event.notificationId);
      final currentState = state;
      if (currentState is NotificationLoaded) {
        final updatedNotifications = currentState.notifications.map((n) {
          if (n.id == event.notificationId) {
            return n.copyWith(isRead: true);
          }
          return n;
        }).toList();

        final newUnreadCount = updatedNotifications
            .where((n) => !n.isRead)
            .length;
        emit(
          currentState.copyWith(
            notifications: updatedNotifications,
            unreadCount: newUnreadCount,
          ),
        );
      }
    } catch (e) {
      emit(NotificationError('Failed to mark as read: ${e.toString()}'));
    }
  }

  /// Handle MarkAllNotificationsAsRead event
  Future<void> _onMarkAllAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repository.markAllAsRead(event.userId);
      final currentState = state;
      if (currentState is NotificationLoaded) {
        final updatedNotifications = currentState.notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();

        emit(
          currentState.copyWith(
            notifications: updatedNotifications,
            unreadCount: 0,
          ),
        );
      }
    } catch (e) {
      emit(NotificationError('Failed to mark all as read: ${e.toString()}'));
    }
  }

  /// Handle NotificationErrorOccurred event
  void _onNotificationErrorOccurred(
    NotificationErrorOccurred event,
    Emitter<NotificationState> emit,
  ) {
    emit(NotificationError(event.message));
  }
}
