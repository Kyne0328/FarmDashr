import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/services/haptic_service.dart';
import 'package:farmdashr/data/models/product/product.dart';
import 'package:farmdashr/data/repositories/auth/vendor_repository.dart'; // Added
import 'package:farmdashr/blocs/cart/cart.dart'; // Added
import 'package:farmdashr/presentation/widgets/common/status_badge.dart';
import 'package:farmdashr/presentation/widgets/vendor_details_bottom_sheet.dart'; // Added
import 'package:farmdashr/presentation/widgets/vendor_products_bottom_sheet.dart'; // Added
import 'package:cached_network_image/cached_network_image.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;
  final bool isFarmerView;
  final String? heroTag;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.isFarmerView = false,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<CartBloc, CartState>(
        listener: (context, state) {
          if (state is CartOperationSuccess) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'View Cart',
                  textColor: Colors.white,
                  onPressed: () => context.go('/customer-cart'),
                ),
              ),
            );
          } else if (state is CartError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductHeader(),
                    const SizedBox(height: AppDimensions.spacingL),
                    _buildDescription(),
                    const SizedBox(height: AppDimensions.spacingXL),
                    _buildProductDetails(),
                    const SizedBox(height: AppDimensions.spacingXL),
                    _buildActionButtons(context),
                    const SizedBox(height: AppDimensions.spacingXL),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: 0.9),
          child: IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: () {
              HapticService.selection();
              context.pop();
            },
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: heroTag ?? 'product_image_${product.id}',
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              image: product.imageUrls.isNotEmpty
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(
                        product.imageUrls.first,
                      ),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: product.imageUrls.isEmpty
                ? const Icon(
                    Icons.image_outlined,
                    size: 64,
                    color: AppColors.textTertiary,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildProductHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTextStyles.h2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    'Sold by ${product.farmerName}',
                    style: AppTextStyles.body2Secondary,
                  ),
                ],
              ),
            ),
            if (product.isLowStock) StatusBadge.lowStock(),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingM),
        const SizedBox(height: AppDimensions.spacingL),
        Text(
          product.formattedPrice,
          style: AppTextStyles.h1.copyWith(
            color: AppColors.info,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Description', style: AppTextStyles.h3),
        const SizedBox(height: AppDimensions.spacingS),
        Text(
          product.description ??
              'Fresh, locally-grown ${product.name.toLowerCase()} from our farm. Harvested at peak ripeness for the best flavor and nutrition. Perfect for salads, snacking, or your favorite recipes.',
          style: AppTextStyles.body2Secondary.copyWith(height: 1.5),
        ),
      ],
    );
  }

  Widget _buildProductDetails() {
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
          Text('Product Details', style: AppTextStyles.h3),
          const SizedBox(height: AppDimensions.spacingM),
          _buildDetailRow('Category', product.category.displayName),
          _buildDetailRow(
            'Availability',
            product.currentStock > 0 ? 'In Stock' : 'Out of Stock',
            valueColor: product.currentStock > 0
                ? AppColors.success
                : AppColors.error,
          ),
          if (isFarmerView) ...[
            _buildDetailRow('SKU', product.sku),
            _buildDetailRow('Current Stock', '${product.currentStock}'),
            _buildDetailRow('Min Stock', '${product.minStock}'),
            _buildDetailRow('Total Revenue', product.formattedRevenue),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body2Secondary),
          Text(
            value,
            style: AppTextStyles.body2.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (isFarmerView) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticService.selection();
                context.push('/add-product', extra: product);
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () {
              HapticService.light();
              context.read<CartBloc>().add(AddToCart(product));
            },
            icon: const Icon(Icons.add),
            label: const Text('Add to Cart'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: () async {
              HapticService.selection();
              // Show loading then fetch vendor details
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );

              try {
                final vendor = await VendorRepository().getVendorById(
                  product.farmerId,
                );

                if (context.mounted) {
                  Navigator.pop(context); // Close loading dialog

                  if (vendor != null) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => VendorDetailsBottomSheet(
                        vendor: vendor,
                        onViewProducts: () {
                          Navigator.pop(ctx);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) =>
                                VendorProductsBottomSheet(vendor: vendor),
                          );
                        },
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vendor details not found')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close loading dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
            ),
            child: Text(
              'View Vendor',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
