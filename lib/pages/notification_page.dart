import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:farmdashr/blocs/auth/auth.dart';
import 'package:farmdashr/blocs/notification/notification.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:farmdashr/data/models/notification/notification.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/presentation/widgets/common/shimmer_loader.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/presentation/widgets/common/empty_state_widget.dart';
import 'package:go_router/go_router.dart';

/// Notification center page showing all notifications
class NotificationPage extends StatelessWidget {
  final UserType? userType;

  const NotificationPage({super.key, this.userType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Notifications', style: AppTextStyles.h2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is NotificationLoaded &&
                  state.notifications.isNotEmpty) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.unreadCount > 0)
                      TextButton(
                        onPressed: () {
                          final userId = context.read<AuthBloc>().state.userId;
                          if (userId != null) {
                            context.read<NotificationBloc>().add(
                              MarkAllNotificationsAsRead(
                                userId: userId,
                                userType: userType,
                              ),
                            );
                          }
                        },
                        child: Text(
                          'Mark all read',
                          style: AppTextStyles.link.copyWith(fontSize: 14),
                        ),
                      ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        final userId = context.read<AuthBloc>().state.userId;
                        if (userId == null) return;

                        if (value == 'clearAll') {
                          _showClearAllConfirmation(context, userId);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'clearAll',
                          child: Text('Clear all notifications'),
                        ),
                      ],
                      icon: const Icon(
                        Icons.more_vert,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading) {
            return SkeletonLoaders.notificationList();
          }

          if (state is NotificationError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  Text(state.message, style: AppTextStyles.body2Secondary),
                ],
              ),
            );
          }

          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                final userId = context.read<AuthBloc>().state.userId;
                if (userId != null) {
                  context.read<NotificationBloc>().add(
                    LoadNotifications(userId: userId, userType: userType),
                  );
                }
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                itemCount: state.notifications.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppDimensions.spacingS),
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  return Dismissible(
                    key: Key(notification.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingL,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusM,
                        ),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      context.read<NotificationBloc>().add(
                        DeleteNotification(notificationId: notification.id),
                      );
                    },
                    child: _NotificationCard(notification: notification),
                  );
                },
              ),
            );
          }

          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget.noNotifications();
  }

  void _showClearAllConfirmation(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to delete all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<NotificationBloc>().add(
                ClearAllNotifications(userId: userId, userType: userType),
              );
              Navigator.pop(context);
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Mark as read when tapped
        if (!notification.isRead) {
          context.read<NotificationBloc>().add(
            MarkNotificationAsRead(notificationId: notification.id),
          );
        }

        // Navigate based on type
        if (notification.orderId != null) {
          final isFarmer = notification.targetUserType == UserType.farmer;
          context.push(
            '/order-detail?id=${notification.orderId}&isFarmer=$isFarmer',
          );
        } else if (notification.type == NotificationType.promotion) {
          context.push('/customer-browse');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.surface
              : AppColors.primaryLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: notification.isRead
                ? AppColors.border
                : AppColors.primary.withValues(alpha: 0.3),
          ),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextStyles.body2.copyWith(
                            fontWeight: notification.isRead
                                ? FontWeight.w400
                                : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Text(notification.timeAgo, style: AppTextStyles.caption),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    notification.body,
                    style: AppTextStyles.body2Secondary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: AppDimensions.spacingS),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.orderUpdate:
        iconData = Icons.shopping_bag_outlined;
        iconColor = AppColors.info;
        break;
      case NotificationType.promotion:
        iconData = Icons.local_offer_outlined;
        iconColor = AppColors.success;
        break;
      case NotificationType.system:
        iconData = Icons.info_outline;
        iconColor = AppColors.textSecondary;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }
}
