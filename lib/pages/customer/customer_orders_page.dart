import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/data/models/order.dart';
import 'package:farmdashr/blocs/order/order.dart';
import 'package:farmdashr/blocs/auth/auth_bloc.dart';
import 'package:farmdashr/blocs/auth/auth_state.dart';

class CustomerOrdersPage extends StatelessWidget {
  const CustomerOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrderBloc()..add(const LoadOrders()),
      child: const _CustomerOrdersContent(),
    );
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

        final customerId = authState.userId;

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
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is OrderError) {
                        return Center(child: Text(state.message));
                      }
                      if (state is OrderLoaded) {
                        // Filter orders for this customer
                        final userOrders = state.orders
                            .where((o) => o.customerId == customerId)
                            .toList();

                        return TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOrdersList(
                              userOrders
                                  .where(
                                    (o) => o.status != OrderStatus.completed,
                                  )
                                  .toList(),
                            ),
                            _buildOrdersList(
                              userOrders
                                  .where(
                                    (o) => o.status == OrderStatus.completed,
                                  )
                                  .toList(),
                            ),
                          ],
                        );
                      }
                      return const Center(child: CircularProgressIndicator());
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
              color: const Color(0xFFF3F4F6),
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
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
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
      return Center(
        child: Text('No orders found', style: AppTextStyles.body2Secondary),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      itemCount: orders.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppDimensions.spacingM),
      itemBuilder: (context, index) => OrderCard(order: orders[index]),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Order order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    Color statusTextColor;

    switch (order.status) {
      case OrderStatus.pending:
        statusColor = const Color(0xFFDBEAFE);
        statusTextColor = AppColors.info;
        break;
      case OrderStatus.ready:
        statusColor = const Color(0xFFD0FAE5);
        statusTextColor = AppColors.success;
        break;
      case OrderStatus.completed:
        statusColor = const Color(0xFFF3F4F6);
        statusTextColor = AppColors.textSecondary;
        break;
    }

    return Container(
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
                    style: AppTextStyles.body2.copyWith(color: AppColors.info),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.itemCount} items',
                    style: AppTextStyles.body2Secondary,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: statusTextColor,
                  ),
                ),
              ),
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
