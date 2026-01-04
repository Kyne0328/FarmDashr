import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/data/repositories/auth/user_repository.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:farmdashr/core/utils/snackbar_helper.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage>
    with WidgetsBindingObserver {
  final UserRepository _userRepo = UserRepository();
  bool _systemPermissionGranted = false;
  bool _pushEnabled = true; // App-level preference

  // Customer settings
  bool _orderUpdates = true;

  // Farmer settings
  bool _newOrders = true;

  bool _isLoading = true;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSystemPermission();
    }
  }

  Future<void> _initializeSettings() async {
    await Future.wait([_loadUserProfile(), _checkSystemPermission()]);
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _userRepo.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          if (profile != null) {
            final prefs = profile.notificationPreferences;
            _pushEnabled = prefs.pushEnabled;
            // Customer
            _orderUpdates = prefs.orderUpdates;
            // Farmer
            _newOrders = prefs.newOrders;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _checkSystemPermission() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (mounted) {
      setState(() {
        _systemPermissionGranted =
            settings.authorizationStatus == AuthorizationStatus.authorized;
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePreferences({
    bool? pushEnabled,
    bool? orderUpdates,
    bool? newOrders,
  }) async {
    if (_userProfile == null) return;

    final currentPrefs = _userProfile!.notificationPreferences;
    final newPrefs = currentPrefs.copyWith(
      pushEnabled: pushEnabled,
      orderUpdates: orderUpdates,
      newOrders: newOrders,
    );

    final updatedProfile = _userProfile!.copyWith(
      notificationPreferences: newPrefs,
    );

    // Optimistic update
    setState(() {
      if (pushEnabled != null) _pushEnabled = pushEnabled;
      if (orderUpdates != null) _orderUpdates = orderUpdates;
      if (newOrders != null) _newOrders = newOrders;
      _userProfile = updatedProfile;
    });

    try {
      await _userRepo.update(updatedProfile);
    } catch (e) {
      // Revert if failed
      if (mounted) {
        SnackbarHelper.showError(context, 'Failed to save settings: $e');
        setState(() {
          _pushEnabled = currentPrefs.pushEnabled;
          _orderUpdates = currentPrefs.orderUpdates;
          _newOrders = currentPrefs.newOrders;
          _userProfile = _userProfile!.copyWith(
            notificationPreferences: currentPrefs,
          );
        });
      }
    }
  }

  Future<void> _requestSystemPermission() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (mounted) {
      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized;
      setState(() {
        _systemPermissionGranted = granted;
      });

      if (granted) {
        // Enable push notifications since user granted permission
        await _updatePreferences(pushEnabled: true);
        if (mounted) {
          SnackbarHelper.showSuccess(context, 'Notifications enabled');
        }
      } else {
        if (mounted) {
          SnackbarHelper.showError(
            context,
            'System permission denied. Please enable in settings.',
          );
        }
      }
    }
  }

  Future<void> _togglePushNotifications(bool value) async {
    if (value) {
      if (!_systemPermissionGranted) {
        await _requestSystemPermission();
      } else {
        await _updatePreferences(pushEnabled: true);
      }
    } else {
      await _updatePreferences(pushEnabled: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine user role for conditional UI
    final isFarmer = _userProfile?.isFarmer ?? false;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Notification Settings', style: AppTextStyles.h3),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader('Push Notifications'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SwitchListTile(
                    value: _pushEnabled && _systemPermissionGranted,
                    onChanged: _togglePushNotifications,
                    activeTrackColor: AppColors.primary,
                    title: const Text(
                      'Enable Push Notifications',
                      style: AppTextStyles.body1,
                    ),
                    subtitle: Text(
                      _systemPermissionGranted
                          ? 'Receive notifications even when app is closed'
                          : 'System permission required',
                      style: AppTextStyles.caption,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  isFarmer ? 'Farmer Notifications' : 'Customer Notifications',
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (isFarmer) ...[
                        _buildSwitchTile(
                          title: 'New Orders',
                          subtitle: 'Get notified when you receive a new order',
                          value: _newOrders,
                          onChanged: (v) => _updatePreferences(newOrders: v),
                        ),
                      ] else ...[
                        _buildSwitchTile(
                          title: 'Order Updates',
                          subtitle:
                              'Get notified when your order status changes',
                          value: _orderUpdates,
                          onChanged: (v) => _updatePreferences(orderUpdates: v),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'In-app notifications will always be shown regardless of push notification settings.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.primary,
      title: Text(title, style: AppTextStyles.body1),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
    );
  }
}
