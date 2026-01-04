import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:farmdashr/core/utils/snackbar_helper.dart';
import 'package:farmdashr/data/repositories/repositories.dart';

/// Service for showing in-app notifications when the app is in foreground.
/// Respects user's notification preferences.
class InAppNotificationService {
  static final InAppNotificationService _instance =
      InAppNotificationService._internal();

  factory InAppNotificationService() => _instance;

  InAppNotificationService._internal();

  final UserRepository _userRepo = FirestoreUserRepository();
  BuildContext? _context;

  /// Initialize the service with the app's context
  void init(BuildContext context) {
    _context = context;
    _setupForegroundMessageHandler();
  }

  /// Update the context when needed
  void updateContext(BuildContext context) {
    _context = context;
  }

  /// Set up Firebase Messaging foreground handler
  void _setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('Foreground message received: ${message.notification?.title}');

      if (_context == null || !_context!.mounted) {
        debugPrint('No valid context for in-app notification');
        return;
      }

      // Check if user has in-app notifications enabled
      final shouldShow = await _shouldShowInAppNotification();
      if (!shouldShow) {
        debugPrint('In-app notifications disabled by user preference');
        return;
      }

      final notification = message.notification;
      if (notification != null) {
        _showNotification(
          title: notification.title ?? 'Notification',
          body: notification.body ?? '',
          data: message.data,
        );
      }
    });
  }

  /// Check user preferences to determine if in-app notification should show
  Future<bool> _shouldShowInAppNotification() async {
    try {
      final profile = await _userRepo.getCurrentUserProfile();
      if (profile == null) return true; // Default to showing if no profile

      return profile.notificationPreferences.inAppNotifications;
    } catch (e) {
      debugPrint('Error checking notification preferences: $e');
      return true; // Default to showing on error
    }
  }

  /// Show the in-app notification using the snackbar helper
  void _showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    if (_context == null || !_context!.mounted) return;

    // Determine icon based on notification type
    IconData icon = Icons.notifications_active_outlined;
    if (data != null) {
      final type = data['type'] as String?;
      switch (type) {
        case 'order_update':
          icon = Icons.local_shipping_outlined;
          break;
        case 'new_order':
          icon = Icons.shopping_bag_outlined;
          break;
        case 'order_cancelled':
          icon = Icons.cancel_outlined;
          break;
        default:
          icon = Icons.notifications_active_outlined;
      }
    }

    SnackbarHelper.showNotification(
      _context!,
      title: title,
      body: body,
      icon: icon,
      onTap: () {
        // Handle notification tap - navigate based on data if needed
        _handleNotificationTap(data);
      },
    );
  }

  /// Handle notification tap action
  void _handleNotificationTap(Map<String, dynamic>? data) {
    if (data == null || _context == null) return;

    // Future: Navigate to relevant page based on notification type
    // For now, just log the tap
    debugPrint('Notification tapped with data: $data');
  }
}
