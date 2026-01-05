import 'package:flutter/material.dart';
import 'package:farmdashr/data/repositories/repositories.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/services/haptic_service.dart';

import 'package:farmdashr/data/models/order/order.dart';
import 'package:farmdashr/data/models/product/product.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:farmdashr/blocs/order/order.dart';
import 'package:farmdashr/blocs/product/product.dart';
import 'package:farmdashr/presentation/widgets/common/stat_card.dart';
import 'package:farmdashr/presentation/widgets/common/status_badge.dart';
import 'package:farmdashr/presentation/widgets/notification_badge.dart';
import 'package:farmdashr/presentation/widgets/common/shimmer_loader.dart';
import 'package:farmdashr/presentation/widgets/common/empty_state_widget.dart';

class FarmerHomePage extends StatefulWidget {
  const FarmerHomePage({super.key});

  @override
  State<FarmerHomePage> createState() => _FarmerHomePageState();
}

class _FarmerHomePageState extends State<FarmerHomePage> {
  UserProfile? _userProfile;
  final _userRepository = FirestoreUserRepository();

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
                  if (orderState is OrderLoading) {
                    return SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppDimensions.paddingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Skeleton
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShimmerBox(
                                    width: 120,
                                    height: 24,
                                    borderRadius: 4,
                                  ),
                                  const SizedBox(height: 8),
                                  ShimmerBox(
                                    width: 180,
                                    height: 16,
                                    borderRadius: 4,
                                  ),
                                ],
                              ),
                              ShimmerBox(
                                width: 40,
                                height: 40,
                                borderRadius: AppDimensions.radiusM,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spacingXL),

                          // Stats Skeleton
                          SkeletonLoaders.statGrid(),
                          const SizedBox(height: AppDimensions.spacingXL),

                          // Quick Actions Skeleton
                          ShimmerBox(width: 100, height: 20, borderRadius: 4),
                          const SizedBox(height: AppDimensions.spacingM),
                          Row(
                            children: [
                              Expanded(
                                child: ShimmerBox(
                                  width: double.infinity,
                                  height: 50,
                                  borderRadius: AppDimensions.radiusXL,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.spacingM),
                              Expanded(
                                child: ShimmerBox(
                                  width: double.infinity,
                                  height: 50,
                                  borderRadius: AppDimensions.radiusXL,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spacingXL),

                          // Recent Orders Skeleton
                          ShimmerBox(width: 120, height: 20, borderRadius: 4),
                          const SizedBox(height: AppDimensions.spacingM),
                          SkeletonLoaders.orderCard(),
                          const SizedBox(height: AppDimensions.spacingM),
                          SkeletonLoaders.orderCard(),
                        ],
                      ),
                    );
                  }

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
          onTap: () => context.push('/notifications?role=farmer'),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textPrimary,
              size: 24,
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

    // Realized Revenue: Only count COMPLETED orders
    final todaySales = todayOrders
        .where((o) => o.status == OrderStatus.completed)
        .fold(0.0, (sum, o) => sum + o.amount);

    final totalRevenue = orders
        .where((o) => o.status == OrderStatus.completed)
        .fold(0.0, (sum, o) => sum + o.amount);
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
                onTap: () {
                  HapticService.selection();
                  context.go('/inventory-page');
                },
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: _QuickActionButton(
                title: 'Check Orders',
                backgroundColor: AppColors.actionOrangeBackground,
                borderColor: AppColors.actionOrangeLight,
                textColor: AppColors.actionOrange,
                onTap: () {
                  HapticService.selection();
                  context.go('/orders-page');
                },
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
              child: EmptyStateWidget(
                title: 'No orders yet',
                subtitle: 'Your recent orders will appear here',
                icon: Icons.shopping_bag_outlined,
              ),
            ),
          )
        else
          ...recentOrders.asMap().entries.map(
            (entry) => TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 200 + (entry.key * 50)),
              curve: Curves.easeOutQuad,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
                child: _OrderCard(order: entry.value),
              ),
            ),
          ),
      ],
    );
  }
}

/// Quick action button with press animation
class _QuickActionButton extends StatefulWidget {
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
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingL),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
            border: Border.all(
              color: widget.borderColor,
              width: AppDimensions.borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.borderColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.title,
              textAlign: TextAlign.center,
              style: AppTextStyles.body1.copyWith(
                color: widget.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Order card with tap animation
class _OrderCard extends StatefulWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticService.selection();
        context.push(
          '/order-detail',
          extra: {'order': widget.order, 'isFarmerView': true},
        );
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          decoration: BoxDecoration(
            color: _isPressed ? AppColors.background : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
            border: Border.all(
              color: _isPressed
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.border,
              width: AppDimensions.borderWidth,
            ),
            boxShadow: _isPressed
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                      Text(
                        widget.order.customerName,
                        style: AppTextStyles.body1,
                      ),
                      const SizedBox(height: AppDimensions.spacingXS),
                      Text(
                        '${widget.order.itemCount} items • ${widget.order.timeAgo}',
                        style: AppTextStyles.body2Secondary,
                      ),
                    ],
                  ),
                  StatusBadge.fromOrderStatus(widget.order.status),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Text(
                widget.order.formattedAmount,
                style: AppTextStyles.body1.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
