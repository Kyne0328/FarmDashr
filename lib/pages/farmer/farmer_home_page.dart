import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Core constants
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';

// Data models
import 'package:farmdashr/data/models/order/order.dart';

// Shared widgets
import 'package:farmdashr/presentation/widgets/common/stat_card.dart';
import 'package:farmdashr/presentation/widgets/common/status_badge.dart';
import 'package:farmdashr/presentation/widgets/notification_badge.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:farmdashr/blocs/order/order.dart';
import 'package:farmdashr/blocs/product/product.dart';
import 'package:farmdashr/data/models/product/product.dart';
import 'package:farmdashr/data/repositories/auth/user_repository.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';

class FarmerHomePage extends StatefulWidget {
  const FarmerHomePage({super.key});

  @override
  State<FarmerHomePage> createState() => _FarmerHomePageState();
}

class _FarmerHomePageState extends State<FarmerHomePage> {
  UserProfile? _userProfile;
  final _userRepository = UserRepository();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await _userRepository.getCurrentUserProfile();
    if (mounted) {
      setState(() => _userProfile = profile);
      if (profile != null) {
        context.read<OrderBloc>().add(LoadFarmerOrders(profile.id));
        // ProductBloc is already loading all products in main.dart,
        // but we might want to filter or reload if needed.
        // For now, we'll filter in the UI or use products already in state.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<OrderBloc, OrderState>(
                builder: (context, orderState) {
                  // Handle loading state
                  if (orderState is OrderLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Handle error state
                  if (orderState is OrderError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimensions.paddingXL),
                        child: Text(
                          'Error loading orders: ${orderState.message}',
                          style: AppTextStyles.body2Secondary,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return BlocBuilder<ProductBloc, ProductState>(
                    builder: (context, productState) {
                      final orders = orderState is OrderLoaded
                          ? orderState.orders
                          : <Order>[];
                      final products = productState is ProductLoaded
                          ? productState.products
                          : <Product>[];

                      // Filter products for this farmer
                      final farmerProducts = _userProfile != null
                          ? products
                                .where((p) => p.farmerId == _userProfile!.id)
                                .toList()
                          : <Product>[];

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(AppDimensions.paddingL),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(_userProfile?.name),
                            const SizedBox(height: AppDimensions.spacingXL),
                            _buildStatsGrid(orders, farmerProducts),
                            const SizedBox(height: AppDimensions.spacingXL),
                            _buildQuickActionsSection(context),
                            const SizedBox(height: AppDimensions.spacingXL),
                            _buildRecentOrdersSection(orders),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String? name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fresh Market',
                style: AppTextStyles.h1,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDimensions.spacingXS),
              Text(
                name != null ? 'Good morning, $name!' : 'Good morning, farmer!',
                style: AppTextStyles.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        NotificationBadge(
          onTap: () => context.push('/notifications'),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(List<Order> orders, List<Product> products) {
    final now = DateTime.now();
    final todayOrders = orders
        .where(
          (o) =>
              o.createdAt.year == now.year &&
              o.createdAt.month == now.month &&
              o.createdAt.day == now.day,
        )
        .toList();

    final todaySales = todayOrders.fold(0.0, (sum, o) => sum + o.amount);
    final totalRevenue = orders.fold(0.0, (sum, o) => sum + o.amount);
    final uniqueCustomers = orders.map((o) => o.customerId).toSet().length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.attach_money,
                title: "Today's Sales",
                value: '₱${todaySales.toStringAsFixed(0)}',
                theme: const SuccessStatCardTheme(),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingL),
            Expanded(
              child: StatCard(
                icon: Icons.shopping_bag_outlined,
                title: 'Orders',
                value: '${orders.length}',
                theme: const InfoStatCardTheme(),
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
                value: '$uniqueCustomers',
              ),
            ),
            const SizedBox(width: AppDimensions.spacingL),
            Expanded(
              child: StatCard(
                icon: Icons.trending_up,
                title: 'Revenue',
                value: '₱${(totalRevenue / 1000).toStringAsFixed(1)}K',
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

  Widget _buildRecentOrdersSection(List<Order> orders) {
    final recentOrders = orders.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Orders', style: AppTextStyles.h3),
        const SizedBox(height: AppDimensions.spacingM),
        if (recentOrders.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.paddingXL,
              ),
              child: Text('No orders yet', style: AppTextStyles.body2Secondary),
            ),
          )
        else
          ...recentOrders.map(
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
