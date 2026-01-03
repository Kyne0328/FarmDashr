import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:farmdashr/blocs/auth/auth.dart';
import 'package:farmdashr/blocs/notification/notification.dart';
import 'package:farmdashr/data/models/notification/notification.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:go_router/go_router.dart';

/// Notification center page showing all notifications
class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

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
              if (state is NotificationLoaded && state.unreadCount > 0) {
                return TextButton(
                  onPressed: () {
                    final userId = context.read<AuthBloc>().state.userId;
                    if (userId != null) {
                      context.read<NotificationBloc>().add(
                        MarkAllNotificationsAsRead(userId: userId),
                      );
                    }
                  },
                  child: Text(
                    'Mark all read',
                    style: AppTextStyles.link.copyWith(fontSize: 14),
                  ),
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
            return const Center(child: CircularProgressIndicator());
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
                    LoadNotifications(userId: userId),
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
                  return _NotificationCard(notification: notification);
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppDimensions.spacingL),
          const Text('No notifications yet', style: AppTextStyles.h3),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            'You\'ll see updates about your orders here',
            style: AppTextStyles.body2Secondary.copyWith(fontSize: 14),
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

        // Navigate to order if it's an order notification
        if (notification.orderId != null) {
          // TODO: Navigate to order detail page
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
