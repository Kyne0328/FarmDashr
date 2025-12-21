import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Core constants
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';

// Data models
import 'package:farmdashr/data/models/order.dart';

// Shared widgets
import 'package:farmdashr/presentation/widgets/common/stat_card.dart';
import 'package:farmdashr/presentation/widgets/common/status_badge.dart';

class FarmerHomePage extends StatelessWidget {
  const FarmerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Main scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    _buildHeader(),
                    const SizedBox(height: AppDimensions.spacingXL),

                    // Stats Grid
                    _buildStatsGrid(),
                    const SizedBox(height: AppDimensions.spacingXL),

                    // Quick Actions Section
                    _buildQuickActionsSection(context),
                    const SizedBox(height: AppDimensions.spacingXL),

                    // Recent Orders Section
                    _buildRecentOrdersSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title and Greeting
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fresh Market', style: AppTextStyles.h1),
            const SizedBox(height: AppDimensions.spacingXS),
            Text('Good morning, farmer!', style: AppTextStyles.subtitle),
          ],
        ),

        // Notification Bell
        Stack(
          children: [
            Container(
              width: AppDimensions.avatarS,
              height: AppDimensions.avatarS,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.avatarS / 2),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                size: 24,
                color: Color(0xFF697282),
              ),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.errorLight,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.attach_money,
                title: "Today's Sales",
                value: '\$1,247',
                change: '+12%',
              ),
            ),
            const SizedBox(width: AppDimensions.spacingL),
            Expanded(
              child: StatCard(
                icon: Icons.shopping_bag_outlined,
                title: 'Orders',
                value: '23',
                change: '+5',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingL),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.people_outline,
                title: 'Customers',
                value: '156',
                change: '+18%',
              ),
            ),
            const SizedBox(width: AppDimensions.spacingL),
            Expanded(
              child: StatCard(
                icon: Icons.trending_up,
                title: 'Revenue',
                value: '\$8.2K',
                change: '+24%',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTextStyles.h3),
        const SizedBox(height: AppDimensions.spacingM),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                title: 'Manage Inventory',
                backgroundColor: AppColors.actionPurpleBackground,
                borderColor: AppColors.actionPurpleLight,
                textColor: AppColors.actionPurple,
                onTap: () => context.go('/inventory-page'),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: _QuickActionButton(
                title: 'Check Orders',
                backgroundColor: AppColors.actionOrangeBackground,
                borderColor: AppColors.actionOrangeLight,
                textColor: AppColors.actionOrange,
                onTap: () => context.go('/orders-page'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentOrdersSection() {
    // Using Order model's sample data
    final orders = Order.sampleOrders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Orders', style: AppTextStyles.h3),
        const SizedBox(height: AppDimensions.spacingM),
        ...orders.map(
          (order) => Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
            child: _OrderCard(order: order),
          ),
        ),
      ],
    );
  }
}

/// Quick action button widget
class _QuickActionButton extends StatelessWidget {
  final String title;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.title,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingL),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          border: Border.all(
            color: borderColor,
            width: AppDimensions.borderWidth,
          ),
        ),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.body1.copyWith(color: textColor),
          ),
        ),
      ),
    );
  }
}

/// Order card widget - uses shared StatusBadge
class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(
          color: AppColors.border,
          width: AppDimensions.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.customerName, style: AppTextStyles.body1),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    '${order.itemCount} items • ${order.timeAgo}',
                    style: AppTextStyles.body2Secondary,
                  ),
                ],
              ),
              // Using shared StatusBadge widget
              StatusBadge.fromOrderStatus(order.status),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            order.formattedAmount,
            style: AppTextStyles.body1.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
