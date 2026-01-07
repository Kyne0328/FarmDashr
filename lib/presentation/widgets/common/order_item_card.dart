import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/data/models/order/order.dart';
import 'package:farmdashr/presentation/widgets/common/status_badge.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:farmdashr/core/services/haptic_service.dart';
import 'package:farmdashr/data/repositories/auth/user_repository.dart';
import 'package:farmdashr/core/utils/snackbar_helper.dart';
import 'package:farmdashr/presentation/widgets/vendor_details_bottom_sheet.dart';
import 'package:farmdashr/presentation/widgets/vendor_products_bottom_sheet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrderItemCard extends StatefulWidget {
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
  State<OrderItemCard> createState() => _OrderItemCardState();
}

class _OrderItemCardState extends State<OrderItemCard> {
  bool _isLoadingVendor = false;

  void _handleVendorTap(BuildContext context) async {
    if (_isLoadingVendor) return;

    HapticService.selection();
    setState(() => _isLoadingVendor = true);

    try {
      final vendor = await context.read<UserRepository>().getById(
        widget.order.farmerId,
      );

      if (!mounted) return;
      setState(() => _isLoadingVendor = false);

      if (vendor != null) {
        if (!context.mounted) return;
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => VendorDetailsBottomSheet(
            vendor: vendor,
            onViewProducts: () {
              Navigator.pop(ctx);
              showModalBottomSheet(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => VendorProductsBottomSheet(vendor: vendor),
              );
            },
          ),
        );
      } else {
        if (!context.mounted) return;
        SnackbarHelper.showError(context, 'Vendor profile not found.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingVendor = false);
        if (!context.mounted) return;
        SnackbarHelper.showError(context, 'Error loading vendor: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.selection();
        context.push(
          '/order-detail',
          extra: {'order': widget.order, 'isFarmerView': widget.isFarmerView},
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
                  'ORD-${widget.order.id.substring(0, widget.order.id.length >= 6 ? 6 : widget.order.id.length).toUpperCase()}',
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
                      GestureDetector(
                        onTap: widget.isFarmerView
                            ? null
                            : () => _handleVendorTap(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.isFarmerView
                                  ? widget.order.customerName
                                  : widget.order.farmerName,
                              style: AppTextStyles.caption.copyWith(
                                color: widget.isFarmerView
                                    ? AppColors.textTertiary
                                    : AppColors.primary,
                                decoration: widget.isFarmerView
                                    ? null
                                    : TextDecoration.underline,
                                fontWeight: widget.isFarmerView
                                    ? null
                                    : FontWeight.bold,
                              ),
                            ),
                            if (!widget.isFarmerView) ...[
                              const SizedBox(width: 4),
                              if (_isLoadingVendor)
                                const SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      AppColors.primary,
                                    ),
                                  ),
                                )
                              else
                                Icon(
                                  Icons.open_in_new_rounded,
                                  size: 10,
                                  color: AppColors.primary,
                                ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Pickup/Delivery Info
                      if (widget.order.pickupLocation != null)
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
                                widget.order.pickupLocation!,
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
                      widget.order.timeAgo,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                Text(
                  widget.order.formattedAmount,
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
    if (widget.order.items != null && widget.order.items!.isNotEmpty) {
      imageUrl = widget.order.items!.first.productImageUrl;
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
    final badge = StatusBadge.fromOrderStatus(widget.order.status);

    // If farmer view and updates allowed (e.g. pending/preparing/ready), make it interactive
    if (widget.isFarmerView && widget.onStatusUpdate != null) {
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
    if (widget.order.items == null || widget.order.items!.isEmpty) {
      return '${widget.order.itemCount} items';
    }

    final firstItem = widget.order.items!.first.productName;
    if (widget.order.items!.length == 1) {
      return firstItem;
    } else {
      return '$firstItem + ${widget.order.items!.length - 1} others';
    }
  }
}
