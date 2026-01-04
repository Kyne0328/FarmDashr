import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/presentation/widgets/common/status_badge.dart';
import 'package:farmdashr/presentation/widgets/common/empty_state_widget.dart';
import 'package:farmdashr/presentation/widgets/common/shimmer_loader.dart';
import 'package:farmdashr/data/models/order/order.dart';
import 'package:farmdashr/blocs/order/order.dart';
import 'package:farmdashr/blocs/auth/auth_bloc.dart';
import 'package:farmdashr/blocs/auth/auth_state.dart';

class CustomerOrdersPage extends StatelessWidget {
  const CustomerOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Uses the global OrderBloc provided in main.dart
    return const _CustomerOrdersContent();
  }
}

class _CustomerOrdersContent extends StatefulWidget {
  const _CustomerOrdersContent();

  @override
  State<_CustomerOrdersContent> createState() => _CustomerOrdersContentState();
}

class _CustomerOrdersContentState extends State<_CustomerOrdersContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _customerId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start watching orders for the current customer
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && _customerId != authState.userId) {
      _customerId = authState.userId;
      context.read<OrderBloc>().add(WatchCustomerOrders(_customerId!));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Center(child: Text('Please log in to view orders'));
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: BlocBuilder<OrderBloc, OrderState>(
                    builder: (context, state) {
                      if (state is OrderLoading) {
                        return SkeletonLoaders.verticalList(
                          cardBuilder: SkeletonLoaders.orderCard,
                          itemCount: 3,
                        );
                      }
                      if (state is OrderError) {
                        return Center(child: Text(state.message));
                      }
                      if (state is OrderLoaded) {
                        return TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOrdersList(state.currentOrders),
                            _buildOrdersList(state.historyOrders),
                          ],
                        );
                      }
                      return SkeletonLoaders.verticalList(
                        cardBuilder: SkeletonLoaders.orderCard,
                        itemCount: 3,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Orders', style: AppTextStyles.h1),
          const SizedBox(height: AppDimensions.spacingM),
          Container(
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.containerLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              padding: EdgeInsets.zero,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.info,
                borderRadius: BorderRadius.circular(6),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTextStyles.tabLabel,
              tabs: const [
                Tab(text: 'Active'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<Order> orders) {
    if (orders.isEmpty) {
      return EmptyStateWidget.noOrders(
        onBrowse: () => context.go('/customer-browse'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (_customerId != null) {
          context.read<OrderBloc>().add(WatchCustomerOrders(_customerId!));
          await Future.delayed(const Duration(milliseconds: 500));
        }
      },
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        itemCount: orders.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppDimensions.spacingM),
        itemBuilder: (context, index) => OrderCard(order: orders[index]),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Order order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push(
          '/order-detail',
          extra: {'order': order, 'isFarmerView': false},
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ORD-${order.id.substring(0, order.id.length >= 6 ? 6 : order.id.length).toUpperCase()}',
                      style: AppTextStyles.h4,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'From: ${order.farmerName}',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.itemCount} items',
                      style: AppTextStyles.body2Secondary,
                    ),
                  ],
                ),
                StatusBadge.fromOrderStatus(order.status),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: AppColors.border),
            ),
            if (order.pickupLocation != null) ...[
              _IconTextRow(
                icon: Icons.location_on_outlined,
                text: order.pickupLocation!,
              ),
              const SizedBox(height: 8),
            ],
            _IconTextRow(
              icon: Icons.access_time,
              text: order.pickupDate != null && order.pickupTime != null
                  ? '${order.pickupDate} at ${order.pickupTime}'
                  : order.timeAgo,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: AppTextStyles.body2Secondary),
                Text(
                  order.formattedAmount,
                  style: AppTextStyles.h4.copyWith(color: AppColors.info),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconTextRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _IconTextRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppTextStyles.body2Secondary)),
      ],
    );
  }
}
