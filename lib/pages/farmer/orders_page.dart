import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Core constants
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';

// Data models
import 'package:farmdashr/data/models/order.dart';

// BLoC
import 'package:farmdashr/blocs/order/order.dart';

/// Orders Page - uses BLoC pattern for state management.
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Uses the global OrderBloc provided in main.dart
    return const _OrdersPageContent();
  }
}

/// The actual content of the orders page.
class _OrdersPageContent extends StatefulWidget {
  const _OrdersPageContent();

  @override
  State<_OrdersPageContent> createState() => _OrdersPageContentState();
}

class _OrdersPageContentState extends State<_OrdersPageContent> {
  bool _showCurrentOrders = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // BlocListener for showing snackbars on success/error
      body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.primary,
              ),
            );
          } else if (state is OrderError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        // BlocBuilder for rebuilding UI based on state
        child: BlocBuilder<OrderBloc, OrderState>(
          builder: (context, state) {
            // Loading state
            if (state is OrderLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Error state
            if (state is OrderError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message, style: AppTextStyles.body1),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<OrderBloc>().add(const LoadOrders());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Loaded state
            if (state is OrderLoaded) {
              return _buildLoadedContent(context, state);
            }

            // Initial state - trigger load
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, OrderLoaded state) {
    final currentOrders = state.currentOrders;
    final historyOrders = state.historyOrders;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // Dispatch LoadOrders event on pull-to-refresh
                context.read<OrderBloc>().add(const LoadOrders());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text('Orders', style: AppTextStyles.h3),
                    const SizedBox(height: AppDimensions.spacingXL),

                    // Stats Cards Row - using computed properties from state
                    _buildStatsRow(
                      state.pendingCount,
                      state.readyCount,
                      state.orders.length,
                    ),
                    const SizedBox(height: AppDimensions.spacingXL),

                    // Tab Buttons
                    _buildTabButtons(
                      currentOrders.length,
                      historyOrders.length,
                    ),
                    const SizedBox(height: AppDimensions.spacingL),

                    // Order Cards List
                    _buildOrdersList(
                      context,
                      _showCurrentOrders ? currentOrders : historyOrders,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int pendingCount, int readyCount, int totalToday) {
    return Row(
      children: [
        Expanded(
          child: _OrderStatCard(
            label: 'Pending',
            value: '$pendingCount',
            backgroundColor: AppColors.warningBackground,
            borderColor: AppColors.warningLight,
            textColor: AppColors.warning,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: _OrderStatCard(
            label: 'Ready',
            value: '$readyCount',
            backgroundColor: AppColors.successBackground,
            borderColor: AppColors.successBorder,
            textColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: _OrderStatCard(
            label: 'Today',
            value: '$totalToday',
            backgroundColor: AppColors.infoBackground,
            borderColor: AppColors.infoBorder,
            textColor: AppColors.customerAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildTabButtons(int currentCount, int historyCount) {
    return Row(
      children: [
        Expanded(
          child: _TabButton(
            label: 'Current ($currentCount)',
            isActive: _showCurrentOrders,
            onTap: () => setState(() => _showCurrentOrders = true),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: _TabButton(
            label: 'History ($historyCount)',
            isActive: !_showCurrentOrders,
            onTap: () => setState(() => _showCurrentOrders = false),
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersList(BuildContext context, List<Order> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No orders found',
            style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: orders.map((order) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
          child: _OrderCard(
            order: order,
            onStatusUpdate: (newStatus) {
              // Dispatch UpdateOrderStatus event
              context.read<OrderBloc>().add(
                UpdateOrderStatus(orderId: order.id, newStatus: newStatus),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}

// ============================================================================
// Private Widgets
// ============================================================================

class _OrderStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const _OrderStatCard({
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(
          color: borderColor,
          width: AppDimensions.borderWidthThick,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: textColor)),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            value,
            style: AppTextStyles.priceLarge.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: isActive
              ? null
              : Border.all(
                  color: AppColors.border,
                  width: AppDimensions.borderWidthThick,
                ),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.body1.copyWith(
              color: isActive ? Colors.white : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final Function(OrderStatus)? onStatusUpdate;

  const _OrderCard({required this.order, this.onStatusUpdate});

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at $hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push(
          '/order-detail',
          extra: {'order': order, 'isFarmerView': true},
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          border: Border.all(
            color: AppColors.border,
            width: AppDimensions.borderWidthThick,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ORD-${order.id.substring(0, order.id.length >= 6 ? 6 : order.id.length).toUpperCase()}',
                      style: AppTextStyles.body1,
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      order.customerName,
                      style: AppTextStyles.body2Secondary,
                    ),
                  ],
                ),
                _OrderStatusBadge(
                  status: order.status,
                  onTap: onStatusUpdate != null
                      ? () => _showStatusMenu(context)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingM),

            // Date/Time Row
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              text: _formatDateTime(order.createdAt),
            ),
            const SizedBox(height: AppDimensions.spacingS),

            // Time ago Row
            _InfoRow(icon: Icons.access_time, text: order.timeAgo),
            const SizedBox(height: AppDimensions.spacingM),

            if (order.pickupLocation != null) ...[
              _InfoRow(
                icon: Icons.location_on_outlined,
                text: 'Pickup: ${order.pickupLocation}',
              ),
              const SizedBox(height: AppDimensions.spacingS),
              _InfoRow(
                icon: Icons.event,
                text: '${order.pickupDate} at ${order.pickupTime}',
              ),
              const SizedBox(height: AppDimensions.spacingM),
            ],

            // Divider
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: AppDimensions.spacingM),

            // Footer Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.itemCount} items',
                  style: AppTextStyles.body2Tertiary,
                ),
                Text(
                  order.formattedAmount,
                  style: AppTextStyles.body1.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.hourglass_empty, color: Colors.orange),
              title: const Text('Mark as Pending'),
              onTap: () {
                Navigator.pop(context);
                onStatusUpdate?.call(OrderStatus.pending);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.check_circle_outline,
                color: AppColors.primary,
              ),
              title: const Text('Mark as Ready'),
              onTap: () {
                Navigator.pop(context);
                onStatusUpdate?.call(OrderStatus.ready);
              },
            ),
            ListTile(
              leading: const Icon(Icons.done_all, color: Colors.blue),
              title: const Text('Mark as Completed'),
              onTap: () {
                Navigator.pop(context);
                onStatusUpdate?.call(OrderStatus.completed);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppDimensions.iconS, color: AppColors.textTertiary),
        const SizedBox(width: AppDimensions.spacingS),
        Text(text, style: AppTextStyles.body2Tertiary),
      ],
    );
  }
}

class _OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;
  final VoidCallback? onTap;

  const _OrderStatusBadge({required this.status, this.onTap});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case OrderStatus.pending:
        backgroundColor = AppColors.warningBorder;
        borderColor = AppColors.warningLight;
        textColor = AppColors.actionOrange;
        label = 'Pending';
        icon = Icons.hourglass_empty;
        break;
      case OrderStatus.ready:
        backgroundColor = AppColors.successLight;
        borderColor = AppColors.successBorder;
        textColor = AppColors.primaryDark;
        label = 'Ready';
        icon = Icons.check_circle_outline;
        break;
      case OrderStatus.completed:
        backgroundColor = AppColors.infoLight;
        borderColor = AppColors.infoBorder;
        textColor = AppColors.infoDark;
        label = 'Completed';
        icon = Icons.done_all;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: borderColor,
            width: AppDimensions.borderWidthThick,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppDimensions.iconS, color: textColor),
            const SizedBox(width: AppDimensions.spacingXS),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(color: textColor),
            ),
            if (onTap != null) ...[
              const SizedBox(width: AppDimensions.spacingXS),
              Icon(Icons.arrow_drop_down, size: 16, color: textColor),
            ],
          ],
        ),
      ),
    );
  }
}
