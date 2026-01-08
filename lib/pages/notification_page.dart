import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:farmdashr/blocs/auth/auth.dart';
import 'package:farmdashr/blocs/notification/notification.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:farmdashr/data/models/notification/notification.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/presentation/widgets/common/empty_state_widget.dart';
import 'package:farmdashr/presentation/widgets/common/shimmer_loader.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/services/haptic_service.dart';
import 'package:go_router/go_router.dart';

/// Notification center page showing all notifications
class NotificationPage extends StatefulWidget {
  final UserType? userType;

  const NotificationPage({super.key, this.userType});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            if (state is NotificationLoading) {
              return SkeletonLoaders.notificationList();
            }

            if (state is NotificationError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingL),
                    Text('Something went wrong', style: AppTextStyles.h3),
                    const SizedBox(height: AppDimensions.spacingS),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        state.message,
                        style: AppTextStyles.body2Secondary,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is NotificationLoaded) {
              if (state.notifications.isEmpty) {
                return EmptyStateWidget.noNotifications();
              }

              return RefreshIndicator(
                onRefresh: () async {
                  final userId = context.read<AuthBloc>().state.userId;
                  if (userId != null) {
                    context.read<NotificationBloc>().add(
                      LoadNotifications(
                        userId: userId,
                        userType: widget.userType,
                      ),
                    );
                  }
                },
                color: AppColors.primary,
                child: FadeTransition(
                  opacity: _animationController,
                  child: _buildNotificationsList(state.notifications),
                ),
              );
            }

            return EmptyStateWidget.noNotifications();
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.arrow_back, size: 20),
        ),
        onPressed: () => context.pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Notifications', style: AppTextStyles.h2),
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is NotificationLoaded && state.unreadCount > 0) {
                return Text(
                  '${state.unreadCount} unread',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      actions: [
        BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            if (state is NotificationLoaded && state.notifications.isNotEmpty) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.unreadCount > 0)
                    TextButton.icon(
                      onPressed: () {
                        HapticService.selection();
                        final userId = context.read<AuthBloc>().state.userId;
                        if (userId != null) {
                          context.read<NotificationBloc>().add(
                            MarkAllNotificationsAsRead(
                              userId: userId,
                              userType: widget.userType,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('Read all'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        textStyle: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () {
                      final userId = context.read<AuthBloc>().state.userId;
                      if (userId != null) {
                        _showClearAllConfirmation(context, userId);
                      }
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Clear all'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      textStyle: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(width: AppDimensions.paddingM),
      ],
    );
  }

  Widget _buildNotificationsList(List<AppNotification> notifications) {
    // Group notifications by date
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    final todayNotifications = <AppNotification>[];
    final yesterdayNotifications = <AppNotification>[];
    final olderNotifications = <AppNotification>[];

    for (final n in notifications) {
      if (_isSameDay(n.createdAt, today)) {
        todayNotifications.add(n);
      } else if (_isSameDay(n.createdAt, yesterday)) {
        yesterdayNotifications.add(n);
      } else {
        olderNotifications.add(n);
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingL,
        vertical: AppDimensions.paddingM,
      ),
      children: [
        if (todayNotifications.isNotEmpty) ...[
          _buildSectionHeader('Today'),
          const SizedBox(height: AppDimensions.spacingS),
          ...todayNotifications.asMap().entries.map(
            (entry) => _buildAnimatedCard(entry.key, entry.value),
          ),
          const SizedBox(height: AppDimensions.spacingL),
        ],
        if (yesterdayNotifications.isNotEmpty) ...[
          _buildSectionHeader('Yesterday'),
          const SizedBox(height: AppDimensions.spacingS),
          ...yesterdayNotifications.asMap().entries.map(
            (entry) => _buildAnimatedCard(
              entry.key + todayNotifications.length,
              entry.value,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingL),
        ],
        if (olderNotifications.isNotEmpty) ...[
          _buildSectionHeader('Earlier'),
          const SizedBox(height: AppDimensions.spacingS),
          ...olderNotifications.asMap().entries.map(
            (entry) => _buildAnimatedCard(
              entry.key +
                  todayNotifications.length +
                  yesterdayNotifications.length,
              entry.value,
            ),
          ),
        ],
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingS),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(int index, AppNotification notification) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 300)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
        child: Dismissible(
          key: Key(notification.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingL,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.error.withValues(alpha: 0.8),
                  AppColors.error,
                ],
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline, color: Colors.white, size: 24),
                SizedBox(height: 4),
                Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          onDismissed: (direction) {
            HapticService.selection();
            context.read<NotificationBloc>().add(
              DeleteNotification(notificationId: notification.id),
            );
          },
          child: _NotificationCard(notification: notification),
        ),
      ),
    );
  }

  void _showClearAllConfirmation(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline,
                color: AppColors.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Clear All?'),
          ],
        ),
        content: const Text(
          'This will permanently delete all your notifications. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              HapticService.selection();
              context.read<NotificationBloc>().add(
                ClearAllNotifications(
                  userId: userId,
                  userType: widget.userType,
                ),
              );
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatefulWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _handleTap(context);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          decoration: BoxDecoration(
            color: _isPressed
                ? AppColors.background
                : notification.isRead
                ? Colors.white
                : Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            border: Border.all(
              color: notification.isRead
                  ? AppColors.border
                  : AppColors.primary.withValues(alpha: 0.3),
              width: notification.isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: notification.isRead
                    ? Colors.black.withValues(alpha: 0.03)
                    : AppColors.primary.withValues(alpha: 0.08),
                blurRadius: notification.isRead ? 8 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTextStyles.body2.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingS),
                        if (!notification.isRead)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryLight,
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      notification.body,
                      style: AppTextStyles.body2Secondary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          notification.timeAgo,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    HapticService.selection();

    // Mark as read when tapped
    if (!widget.notification.isRead) {
      context.read<NotificationBloc>().add(
        MarkNotificationAsRead(notificationId: widget.notification.id),
      );
    }

    // Navigate based on type
    if (widget.notification.orderId != null) {
      final isFarmer = widget.notification.targetUserType == UserType.farmer;
      context.push(
        '/order-detail?id=${widget.notification.orderId}&isFarmer=$isFarmer',
      );
    } else if (widget.notification.type == NotificationType.promotion) {
      context.push('/customer-browse');
    }
  }

  Widget _buildIcon() {
    IconData iconData;
    List<Color> gradientColors;

    switch (widget.notification.type) {
      case NotificationType.orderUpdate:
        iconData = Icons.shopping_bag_outlined;
        gradientColors = [const Color(0xFF4CAF50), const Color(0xFF81C784)];
        break;
      case NotificationType.promotion:
        iconData = Icons.local_offer_outlined;
        gradientColors = [const Color(0xFFFF9800), const Color(0xFFFFB74D)];
        break;
      case NotificationType.system:
        iconData = Icons.info_outline;
        gradientColors = [const Color(0xFF2196F3), const Color(0xFF64B5F6)];
        break;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.notification.isRead
              ? [
                  gradientColors[0].withValues(alpha: 0.15),
                  gradientColors[1].withValues(alpha: 0.15),
                ]
              : [
                  gradientColors[0].withValues(alpha: 0.2),
                  gradientColors[1].withValues(alpha: 0.2),
                ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(iconData, color: gradientColors[0], size: 24),
    );
  }
}
