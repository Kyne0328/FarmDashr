import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:farmdashr/data/models/product/product.dart';
import 'package:farmdashr/blocs/product/product.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/presentation/widgets/common/product_image.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VendorProductsBottomSheet extends StatelessWidget {
  final UserProfile vendor;

  const VendorProductsBottomSheet({super.key, required this.vendor});

  @override
  Widget build(BuildContext context) {
    final businessInfo = vendor.businessInfo;
    final farmName = businessInfo?.farmName ?? vendor.name;

    return BlocProvider(
      create: (context) =>
          ProductBloc()..add(LoadProducts(farmerId: vendor.id)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXL),
          ),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farmName,
                          style: AppTextStyles.h3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text('Products', style: AppTextStyles.body2Secondary),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Vendor Mini Info
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  color: AppColors.infoBackground.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: vendor.profilePictureUrl != null
                          ? CachedNetworkImageProvider(
                              vendor.profilePictureUrl!,
                            )
                          : null,
                      child: vendor.profilePictureUrl == null
                          ? const Icon(Icons.store, size: 20)
                          : null,
                    ),
                    const SizedBox(width: AppDimensions.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            farmName,
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Products List
            Expanded(
              child: BlocBuilder<ProductBloc, ProductState>(
                builder: (context, state) {
                  if (state is ProductLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is ProductLoaded) {
                    final products = state.products;

                    if (products.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 48,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No products found for this vendor',
                              style: AppTextStyles.body2Secondary,
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(AppDimensions.paddingL),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: AppDimensions.spacingM,
                            mainAxisSpacing: AppDimensions.spacingM,
                          ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return _ProductGridItem(product: products[index]);
                      },
                    );
                  }

                  if (state is ProductError) {
                    return Center(child: Text(state.message));
                  }

                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductGridItem extends StatelessWidget {
  final Product product;

  const _ProductGridItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/product-detail', extra: {'product': product}),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              child: ProductImage(
                product: product,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.radiusL),
                ),
              ),
            ),
            // Product Info
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingS),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTextStyles.body2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.formattedPrice,
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.info,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
