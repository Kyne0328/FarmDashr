import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/data/models/order/order.dart';
import 'package:farmdashr/presentation/widgets/common/status_badge.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:farmdashr/core/services/haptic_service.dart';

class OrderItemCard extends StatelessWidget {
  final Order order;
  final bool isFarmerView;
  final Function(OrderStatus)? onStatusUpdate;

  const OrderItemCard({
    super.key,
    required this.order,
    this.isFarmerView = false,
    this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.selection();
        context.push(
          '/order-detail',
          extra: {'order': order, 'isFarmerView': isFarmerView},
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header: ID and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ORD-${order.id.substring(0, order.id.length >= 6 ? 6 : order.id.length).toUpperCase()}',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                _buildStatusSection(context),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingM),

            // Body: Image and Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                _buildProductImage(),
                const SizedBox(width: AppDimensions.spacingM),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getItemSummary(),
                        style: AppTextStyles.h4.copyWith(fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isFarmerView ? order.customerName : order.farmerName,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Pickup/Delivery Info
                      if (order.pickupLocation != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                order.pickupLocation!,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.spacingM),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: AppDimensions.spacingS),

            // Footer: Time and Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order.timeAgo,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                Text(
                  order.formattedAmount,
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.customerPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    String? imageUrl;
    if (order.items != null && order.items!.isNotEmpty) {
      imageUrl = order.items!.first.productImageUrl;
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        image: imageUrl != null
            ? DecorationImage(
                image: CachedNetworkImageProvider(imageUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: imageUrl == null
          ? const Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: AppColors.textTertiary,
                size: 24,
              ),
            )
          : null,
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    // Basic status badge
    final badge = StatusBadge.fromOrderStatus(order.status);

    // If farmer view and updates allowed (e.g. pending/preparing/ready), make it interactive
    if (isFarmerView && onStatusUpdate != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          badge,
          const SizedBox(width: 4),
          Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textTertiary),
        ],
      );
    }

    return badge;
  }

  String _getItemSummary() {
    if (order.items == null || order.items!.isEmpty) {
      return '${order.itemCount} items';
    }

    final firstItem = order.items!.first.productName;
    if (order.items!.length == 1) {
      return firstItem;
    } else {
      return '$firstItem + ${order.items!.length - 1} others';
    }
  }
}
