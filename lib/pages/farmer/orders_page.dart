import 'package:flutter/material.dart';

// Core constants
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';

// Data models and repositories
import 'package:farmdashr/data/models/order.dart';
import 'package:farmdashr/data/repositories/order_repository.dart';

/// Orders Page - refactored to use SOLID principles and Firestore.
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final OrderRepository _orderRepo = OrderRepository();
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _error;
  bool _showCurrentOrders = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orders = await _orderRepo.getAll();
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load orders';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: AppTextStyles.body1),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadOrders,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final pendingCount = _orders
        .where((o) => o.status == OrderStatus.pending)
        .length;
    final readyCount = _orders
        .where((o) => o.status == OrderStatus.ready)
        .length;
    final currentOrders = _orders
        .where((o) => o.status != OrderStatus.completed)
        .toList();
    final historyOrders = _orders
        .where((o) => o.status == OrderStatus.completed)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadOrders,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text('Orders', style: AppTextStyles.h3),
                      const SizedBox(height: AppDimensions.spacingXL),

                      // Stats Cards Row
                      _buildStatsRow(pendingCount, readyCount, _orders.length),
                      const SizedBox(height: AppDimensions.spacingXL),

                      // Tab Buttons
                      _buildTabButtons(
                        currentOrders.length,
                        historyOrders.length,
                      ),
                      const SizedBox(height: AppDimensions.spacingL),

                      // Order Cards List
                      _buildOrdersList(
                        _showCurrentOrders ? currentOrders : historyOrders,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
            borderColor: const Color(0xFFA4F3CF),
            textColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: _OrderStatCard(
            label: 'Today',
            value: '$totalToday',
            backgroundColor: AppColors.infoBackground,
            borderColor: const Color(0xFFBDDAFF),
            textColor: const Color(0xFF155CFB),
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

  Widget _buildOrdersList(List<Order> orders) {
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
          child: _OrderCard(order: order),
        );
      }).toList(),
    );
  }
}

// Private widgets

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
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontFamily: 'Arimo',
              fontWeight: FontWeight.w400,
            ),
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

  const _OrderCard({required this.order});

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
    return Container(
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
                    'ORD-${order.id.substring(0, 6).toUpperCase()}',
                    style: AppTextStyles.body1,
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(order.customerName, style: AppTextStyles.body2Secondary),
                ],
              ),
              _OrderStatusBadge(status: order.status),
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

  const _OrderStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case OrderStatus.pending:
        backgroundColor = const Color(0xFFFFEDD4);
        borderColor = AppColors.warningLight;
        textColor = AppColors.actionOrange;
        label = 'Pending';
        icon = Icons.hourglass_empty;
        break;
      case OrderStatus.ready:
        backgroundColor = AppColors.successLight;
        borderColor = const Color(0xFFA4F3CF);
        textColor = AppColors.primaryDark;
        label = 'Ready';
        icon = Icons.check_circle_outline;
        break;
      case OrderStatus.completed:
        backgroundColor = AppColors.infoLight;
        borderColor = const Color(0xFFBDDAFF);
        textColor = AppColors.infoDark;
        label = 'Completed';
        icon = Icons.done_all;
        break;
    }

    return Container(
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
          Text(label, style: AppTextStyles.caption.copyWith(color: textColor)),
        ],
      ),
    );
  }
}
