import 'package:flutter/material.dart';
import 'package:farmdashr/data/repositories/repositories.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
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
  final UserRepository _userRepo = FirestoreUserRepository();
  bool _systemPermissionGranted = false;
  bool _pushEnabled = true;
  bool _inAppNotifications = true;

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
            _inAppNotifications = prefs.inAppNotifications;
            _orderUpdates = prefs.orderUpdates;
            _newOrders = prefs.newOrders;
          }
        });
      }
    } catch (_) {
      // Error loading profile - silent fail
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
    bool? inAppNotifications,
    bool? orderUpdates,
    bool? newOrders,
  }) async {
    if (_userProfile == null) return;

    final currentPrefs = _userProfile!.notificationPreferences;
    final newPrefs = currentPrefs.copyWith(
      pushEnabled: pushEnabled,
      inAppNotifications: inAppNotifications,
      orderUpdates: orderUpdates,
      newOrders: newOrders,
    );

    final updatedProfile = _userProfile!.copyWith(
      notificationPreferences: newPrefs,
    );

    // Optimistic update
    setState(() {
      if (pushEnabled != null) _pushEnabled = pushEnabled;
      if (inAppNotifications != null) _inAppNotifications = inAppNotifications;
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
          _inAppNotifications = currentPrefs.inAppNotifications;
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications', style: AppTextStyles.h3),
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
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              children: [
                // Header illustration
                _buildHeader(),
                const SizedBox(height: AppDimensions.spacingXL),

                // Push Notifications Section
                _buildSectionCard(
                  icon: Icons.notifications_active_outlined,
                  iconColor: AppColors.primary,
                  title: 'Push Notifications',
                  subtitle: _systemPermissionGranted
                      ? 'Receive notifications when app is closed'
                      : 'System permission required',
                  trailing: Switch.adaptive(
                    value: _pushEnabled && _systemPermissionGranted,
                    onChanged: _togglePushNotifications,
                    activeTrackColor: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingM),

                // In-App Notifications Section
                _buildSectionCard(
                  icon: Icons.campaign_outlined,
                  iconColor: AppColors.primary,
                  title: 'In-App Notifications',
                  subtitle: 'Show banner when app is open',
                  trailing: Switch.adaptive(
                    value: _inAppNotifications,
                    onChanged: (v) => _updatePreferences(inAppNotifications: v),
                    activeTrackColor: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXL),

                // Notification Types Header
                _buildSectionHeader('Notification Types'),
                const SizedBox(height: AppDimensions.spacingM),

                // Customer Notifications
                _buildNotificationTypeCard(
                  icon: Icons.shopping_bag_outlined,
                  iconColor: AppColors.customerAccent,
                  title: 'Order Updates',
                  subtitle: 'Get notified when your order status changes',
                  value: _orderUpdates,
                  onChanged: (v) => _updatePreferences(orderUpdates: v),
                  badge: 'Customer',
                  badgeColor: AppColors.customerAccent,
                ),
                const SizedBox(height: AppDimensions.spacingM),

                // Farmer Notifications
                _buildNotificationTypeCard(
                  icon: Icons.receipt_long_outlined,
                  iconColor: AppColors.farmerPrimary,
                  title: 'New Orders',
                  subtitle: 'Get notified when you receive a new order',
                  value: _newOrders,
                  onChanged: (v) => _updatePreferences(newOrders: v),
                  badge: 'Farmer',
                  badgeColor: AppColors.farmerPrimary,
                ),
                const SizedBox(height: AppDimensions.spacingXL),

                // Info text
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                        size: AppDimensions.iconS,
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Expanded(
                        child: Text(
                          'Only relevant notifications will be shown based on your account type.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingXL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primaryLight.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.notifications_active,
              color: AppColors.primary,
              size: AppDimensions.iconL,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stay Updated',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Customize how you receive order updates and alerts',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
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

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Icon(icon, color: iconColor, size: AppDimensions.iconM),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body1),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildNotificationTypeCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required String badge,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Icon(icon, color: iconColor, size: AppDimensions.iconM),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title, style: AppTextStyles.body1),
                        const SizedBox(width: AppDimensions.spacingS),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusS,
                            ),
                          ),
                          child: Text(
                            badge,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: badgeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
