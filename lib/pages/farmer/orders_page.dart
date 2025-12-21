import 'package:flutter/material.dart';

// Core constants
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';

/// Orders Page - refactored to use SOLID principles.
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  bool _showCurrentOrders = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text('Orders', style: AppTextStyles.h3),
                    const SizedBox(height: AppDimensions.spacingXL),

                    // Stats Cards Row
                    _buildStatsRow(),
                    const SizedBox(height: AppDimensions.spacingXL),

                    // Tab Buttons
                    _buildTabButtons(),
                    const SizedBox(height: AppDimensions.spacingL),

                    // Order Cards List
                    _buildOrdersList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _OrderStatCard(
            label: 'Pending',
            value: '1',
            backgroundColor: AppColors.warningBackground,
            borderColor: AppColors.warningLight,
            textColor: AppColors.warning,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: _OrderStatCard(
            label: 'Ready',
            value: '1',
            backgroundColor: AppColors.successBackground,
            borderColor: const Color(0xFFA4F3CF),
            textColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: _OrderStatCard(
            label: 'Today',
            value: '3',
            backgroundColor: AppColors.infoBackground,
            borderColor: const Color(0xFFBDDAFF),
            textColor: const Color(0xFF155CFB),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButtons() {
    return Row(
      children: [
        Expanded(
          child: _TabButton(
            label: 'Current (3)',
            isActive: _showCurrentOrders,
            onTap: () => setState(() => _showCurrentOrders = true),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: _TabButton(
            label: 'History (3)',
            isActive: !_showCurrentOrders,
            onTap: () => setState(() => _showCurrentOrders = false),
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersList() {
    final currentOrders = [
      _OrderData(
        orderId: 'ORD-001',
        customerName: 'Sarah Johnson',
        status: _OrderStatus.newOrder,
        dateTime: '2025-11-28 at 10:00 AM',
        location: 'Downtown Market',
        itemCount: 3,
        amount: '\$32.48',
      ),
      _OrderData(
        orderId: 'ORD-002',
        customerName: 'Mike Chen',
        status: _OrderStatus.preparing,
        dateTime: '2025-11-28 at 2:00 PM',
        location: 'Northside Farmers Market',
        itemCount: 3,
        amount: '\$31.50',
      ),
      _OrderData(
        orderId: 'ORD-003',
        customerName: 'Emily Davis',
        status: _OrderStatus.ready,
        dateTime: '2025-11-28 at 11:00 AM',
        location: 'Downtown Market',
        itemCount: 2,
        amount: '\$19.50',
      ),
    ];

    return Column(
      children: currentOrders.map((order) {
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
  final _OrderData order;

  const _OrderCard({required this.order});

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
                  Text(order.orderId, style: AppTextStyles.body1),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(order.customerName, style: AppTextStyles.body2Secondary),
                ],
              ),
              _OrderStatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),

          // Date/Time Row
          _InfoRow(icon: Icons.calendar_today_outlined, text: order.dateTime),
          const SizedBox(height: AppDimensions.spacingS),

          // Location Row
          _InfoRow(icon: Icons.location_on_outlined, text: order.location),
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
                order.amount,
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
  final _OrderStatus status;

  const _OrderStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case _OrderStatus.newOrder:
        backgroundColor = const Color(0xFFFFEDD4);
        borderColor = AppColors.warningLight;
        textColor = AppColors.actionOrange;
        label = 'New Order';
        icon = Icons.fiber_new_outlined;
        break;
      case _OrderStatus.preparing:
        backgroundColor = AppColors.infoLight;
        borderColor = const Color(0xFFBDDAFF);
        textColor = AppColors.infoDark;
        label = 'Preparing';
        icon = Icons.hourglass_empty;
        break;
      case _OrderStatus.ready:
        backgroundColor = AppColors.successLight;
        borderColor = const Color(0xFFA4F3CF);
        textColor = AppColors.primaryDark;
        label = 'Ready';
        icon = Icons.check_circle_outline;
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

// Private data models
enum _OrderStatus { newOrder, preparing, ready }

class _OrderData {
  final String orderId;
  final String customerName;
  final _OrderStatus status;
  final String dateTime;
  final String location;
  final int itemCount;
  final String amount;

  _OrderData({
    required this.orderId,
    required this.customerName,
    required this.status,
    required this.dateTime,
    required this.location,
    required this.itemCount,
    required this.amount,
  });
}
