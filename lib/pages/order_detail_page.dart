import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/utils/snackbar_helper.dart';
import 'package:farmdashr/presentation/widgets/common/farm_button.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/presentation/widgets/common/status_badge.dart';
import 'package:farmdashr/presentation/widgets/common/map_display_widget.dart';
import 'package:farmdashr/data/models/order/order.dart';
import 'package:farmdashr/blocs/order/order.dart';

/// A unified order detail page for both customers and farmers.
/// Displays order items, pickup details, special instructions, and actions.
class OrderDetailPage extends StatelessWidget {
  final Order order;
  final bool isFarmerView;

  const OrderDetailPage({
    super.key,
    required this.order,
    this.isFarmerView = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderOperationSuccess) {
          SnackbarHelper.showSuccess(context, state.message);
          context.pop();
        } else if (state is OrderError) {
          SnackbarHelper.showError(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Order Details',
            style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderHeader(),
              const SizedBox(height: AppDimensions.spacingL),
              _buildStatusSection(context),
              const SizedBox(height: AppDimensions.spacingL),
              _buildOrderItemsSection(),
              const SizedBox(height: AppDimensions.spacingL),
              if (order.pickupLocation != null ||
                  order.pickupDate != null ||
                  order.pickupTime != null)
                _buildPickupDetailsSection(),
              if (order.specialInstructions != null &&
                  order.specialInstructions!.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.spacingL),
                _buildSpecialInstructionsSection(),
              ],
              const SizedBox(height: AppDimensions.spacingL),
              _buildTotalSection(),
              const SizedBox(height: AppDimensions.spacingXL),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ORD-${order.id.substring(0, order.id.length >= 6 ? 6 : order.id.length).toUpperCase()}',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 4),
              Text(
                isFarmerView
                    ? 'Customer: ${order.customerName}'
                    : 'From: ${order.farmerName}',
                style: AppTextStyles.body2Secondary,
              ),
              const SizedBox(height: 4),
              Text(order.timeAgo, style: AppTextStyles.caption),
            ],
          ),
          StatusBadge.fromOrderStatus(
            order.status,
            icon: _getStatusIcon(order.status),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    // Hide status section for completed or cancelled orders (terminal states)
    if (!isFarmerView ||
        order.status == OrderStatus.completed ||
        order.status == OrderStatus.cancelled) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Update Status', style: AppTextStyles.h4),
          const SizedBox(height: AppDimensions.spacingM),
          Row(
            children: [
              Expanded(
                child: _StatusButton(
                  label: 'Pending',
                  isActive: order.status == OrderStatus.pending,
                  color: AppColors.warning,
                  onTap: () => _updateStatus(context, OrderStatus.pending),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: _StatusButton(
                  label: 'Preparing',
                  isActive: order.status == OrderStatus.preparing,
                  color: AppColors.actionPurple,
                  onTap: () => _updateStatus(context, OrderStatus.preparing),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Row(
            children: [
              Expanded(
                child: _StatusButton(
                  label: 'Ready',
                  isActive: order.status == OrderStatus.ready,
                  color: AppColors.success,
                  onTap: () => _updateStatus(context, OrderStatus.ready),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: _StatusButton(
                  label: 'Completed',
                  isActive: order.status == OrderStatus.completed,
                  color: AppColors.info,
                  onTap: () => _showCompleteConfirmation(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Row(
            children: [
              Expanded(
                child: _StatusButton(
                  label: 'Cancelled',
                  isActive: order.status == OrderStatus.cancelled,
                  color: AppColors.error,
                  onTap: () =>
                      _showCancelConfirmation(context, isFarmerAction: true),
                ),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  void _updateStatus(BuildContext context, OrderStatus newStatus) {
    context.read<OrderBloc>().add(
      UpdateOrderStatus(orderId: order.id, newStatus: newStatus),
    );
  }

  Widget _buildOrderItemsSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order Items', style: AppTextStyles.h4),
              Text(
                '${order.itemCount} items',
                style: AppTextStyles.body2Secondary,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          const Divider(color: AppColors.border),
          if (order.items != null && order.items!.isNotEmpty)
            ...order.items!.map((item) => _OrderItemRow(item: item))
          else
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.paddingM,
              ),
              child: Text(
                'No item details available',
                style: AppTextStyles.body2Secondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPickupDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pickup Details', style: AppTextStyles.h4),
          const SizedBox(height: AppDimensions.spacingM),
          if (order.pickupLocation != null)
            _DetailRow(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: order.pickupLocation!,
            ),
          if (order.pickupDate != null) ...[
            const SizedBox(height: AppDimensions.spacingS),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Date',
              value: order.pickupDate!,
            ),
          ],
          if (order.pickupTime != null) ...[
            const SizedBox(height: AppDimensions.spacingS),
            _DetailRow(
              icon: Icons.access_time,
              label: 'Time',
              value: order.pickupTime!,
            ),
          ],
          // Map display for pickup location
          if (order.pickupLocationCoordinates != null) ...[
            const SizedBox(height: AppDimensions.spacingL),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              child: MapDisplayWidget(
                markers: [
                  MapMarkerData(
                    id: 'pickup',
                    location: order.pickupLocationCoordinates!,
                    title: order.pickupLocation ?? 'Pickup Location',
                  ),
                ],
                height: 150,
                showDirectionsButton: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecialInstructionsSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.infoBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.infoBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notes_outlined, size: 20, color: AppColors.info),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                'Special Instructions',
                style: AppTextStyles.h4.copyWith(color: AppColors.infoDark),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            order.specialInstructions!,
            style: AppTextStyles.body1.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.successBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total Amount', style: AppTextStyles.h4),
          Text(
            order.formattedAmount,
            style: AppTextStyles.priceLarge.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    // Customer can cancel if order is pending
    if (!isFarmerView && order.status == OrderStatus.pending) {
      return SizedBox(
        width: double.infinity,
        child: FarmButton(
          label: 'Cancel Order',
          icon: Icons.cancel_outlined,
          onPressed: () => _showCancelConfirmation(context),
          style: FarmButtonStyle.danger,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _showCancelConfirmation(
    BuildContext context, {
    bool isFarmerAction = false,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        ),
        backgroundColor: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                decoration: const BoxDecoration(
                  color: AppColors.errorBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 40,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXL),
              Text(
                'Cancel this Order?',
                style: AppTextStyles.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                'Are you sure? This will mark the order as cancelled and cannot be reversed.',
                style: AppTextStyles.body2Secondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spacingXXL),
              SizedBox(
                width: double.infinity,
                child: FarmButton(
                  label: 'Cancel Order',
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    context.read<OrderBloc>().add(DeleteOrder(order.id));
                  },
                  style: FarmButtonStyle.danger,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              SizedBox(
                width: double.infinity,
                child: FarmButton(
                  label: 'No, Keep Order',
                  onPressed: () => Navigator.pop(dialogContext),
                  style: FarmButtonStyle.ghost,
                  textColor: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        ),
        backgroundColor: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                decoration: const BoxDecoration(
                  color: AppColors.infoBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.done_all_rounded,
                  color: AppColors.info,
                  size: 40,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXL),
              Text(
                'Complete this Order?',
                style: AppTextStyles.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                'This will mark the order as completed. This action cannot be undone.',
                style: AppTextStyles.body2Secondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spacingXXL),
              SizedBox(
                width: double.infinity,
                child: FarmButton(
                  label: 'Complete Order',
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    context.read<OrderBloc>().add(
                      UpdateOrderStatus(
                        orderId: order.id,
                        newStatus: OrderStatus.completed,
                      ),
                    );
                  },
                  style: FarmButtonStyle.primary,
                  backgroundColor: AppColors.info,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              SizedBox(
                width: double.infinity,
                child: FarmButton(
                  label: 'No, Keep as Ready',
                  onPressed: () => Navigator.pop(dialogContext),
                  style: FarmButtonStyle.ghost,
                  textColor: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.hourglass_empty;
      case OrderStatus.preparing:
        return Icons.moped_outlined;
      case OrderStatus.ready:
        return Icons.check_circle_outline;
      case OrderStatus.completed:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.close;
    }
  }
}

// =============================================================================
// Private Widgets
// =============================================================================

class _StatusButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? color : AppColors.containerLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: isActive ? color : AppColors.border,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.body2.copyWith(
              color: isActive ? Colors.white : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final OrderItem item;

  const _OrderItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingS),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Center(
              child: Text(
                '${item.quantity}x',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: AppTextStyles.body1),
                Text(item.formattedPrice, style: AppTextStyles.body2Secondary),
              ],
            ),
          ),
          Text(
            item.formattedTotal,
            style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppDimensions.spacingS),
        Text('$label: ', style: AppTextStyles.body2Secondary),
        Expanded(child: Text(value, style: AppTextStyles.body1)),
      ],
    );
  }
}
