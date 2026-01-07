import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:farmdashr/blocs/auth/auth.dart';
import 'package:farmdashr/blocs/product/product.dart';
import 'package:farmdashr/blocs/vendor/vendor.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/presentation/widgets/vendor_details_bottom_sheet.dart';
import 'package:farmdashr/presentation/widgets/vendor_products_bottom_sheet.dart';
import 'package:farmdashr/presentation/widgets/notification_badge.dart';
import 'package:farmdashr/presentation/widgets/common/product_image.dart';
import 'package:farmdashr/presentation/widgets/common/shimmer_loader.dart';
import 'package:farmdashr/presentation/widgets/common/empty_state_widget.dart';
import 'package:farmdashr/data/models/product/product.dart';
import 'package:farmdashr/presentation/extensions/product_category_extension.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:farmdashr/core/services/haptic_service.dart';
import 'package:farmdashr/presentation/widgets/common/farm_text_field.dart';
import 'package:farmdashr/presentation/widgets/home/promo_carousel.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  @override
  void initState() {
    super.initState();
    // Trigger initial load
    final userId = context.read<AuthBloc>().state.userId;
    context.read<VendorBloc>().add(LoadVendors(excludeUserId: userId));
    context.read<ProductBloc>().add(LoadProducts(excludeFarmerId: userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final userId = context.read<AuthBloc>().state.userId;
            context.read<VendorBloc>().add(LoadVendors(excludeUserId: userId));
            context.read<ProductBloc>().add(
              LoadProducts(excludeFarmerId: userId),
            );
          },
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverAppBar(
                backgroundColor: AppColors.background,
                pinned: true,
                floating: true,
                automaticallyImplyLeading: false,
                toolbarHeight: 70, // Slight adjustments for search bar height
                surfaceTintColor: Colors.transparent, // Avoid tint on scroll
                title: _buildSearchBar(context),
                titleSpacing: 0,
              ),
              SliverToBoxAdapter(
                child: const SizedBox(height: AppDimensions.spacingL),
              ),
              SliverToBoxAdapter(child: const PromoCarousel()),
              SliverToBoxAdapter(
                child: const SizedBox(height: AppDimensions.spacingXL),
              ),

              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildSectionHeader(
                      context,
                      'Explore Categories',
                      onSeeAll: () => context.go('/customer-browse'),
                    ),
                    const SizedBox(height: AppDimensions.spacingM),
                    _buildCategoriesList(context),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: const SizedBox(height: AppDimensions.spacingXL),
              ),

              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildSectionHeader(
                      context,
                      'Featured Vendors',
                      onSeeAll: () =>
                          context.go('/customer-browse?tab=vendors'),
                    ),
                    const SizedBox(height: AppDimensions.spacingM),
                    _buildFeaturedVendorsList(),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: const SizedBox(height: AppDimensions.spacingXL),
              ),

              // Popular Products
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildSectionHeader(
                      context,
                      'Popular This Week',
                      onSeeAll: () => context.go('/customer-browse'),
                    ),
                    const SizedBox(height: AppDimensions.spacingM),
                    _buildPopularProductsList(context),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: const SizedBox(height: AppDimensions.spacingXL * 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final name = state.displayName ?? 'Friend';
        // Get just the first name
        final firstName = name.split(' ').first;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingL,
            vertical: AppDimensions.paddingM,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Hello, $firstName',
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('👋', style: TextStyle(fontSize: 20)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Find fresh local produce',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  // Map button
                  GestureDetector(
                    onTap: () => context.push('/nearby-farms'),
                    child: Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.map_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                  ),
                  // Notification button
                  NotificationBadge(
                    onTap: () => context.push('/notifications?role=customer'),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FarmTextField(
          hint: 'Search for products, vendors...',
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          textInputAction: TextInputAction.search,
          fillColor: Colors.white,
          onSubmitted: (query) {
            if (query.isNotEmpty) {
              context.go('/customer-browse?q=${Uri.encodeComponent(query)}');
            } else {
              context.go('/customer-browse');
            }
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    required VoidCallback onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.h3),
          InkWell(
            onTap: onSeeAll,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'See All',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList(BuildContext context) {
    final categories = ProductCategory.values;

    return SizedBox(
      height: 105,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppDimensions.spacingM),
        itemBuilder: (context, index) {
          final category = categories[index];
          return InkWell(
            onTap: () {
              HapticService.selection();
              context.go('/customer-browse?category=${category.name}');
            },
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      category.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  category.displayName,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedVendorsList() {
    return BlocBuilder<VendorBloc, VendorState>(
      builder: (context, vendorState) {
        if (vendorState is VendorInitial) {
          // Already loading in initState, checking here just in case
        }

        if (vendorState is VendorLoading) {
          return SkeletonLoaders.horizontalList(
            cardBuilder: SkeletonLoaders.vendorCard,
            height: 190,
            itemCount: 3,
          );
        }

        if (vendorState is VendorLoaded) {
          final vendors = vendorState.vendors.take(5).toList();
          if (vendors.isEmpty) {
            return Center(
              child: EmptyStateWidget(
                title: 'No vendors found',
                subtitle: 'Try adjusting your search filters',
                icon: Icons.store_outlined,
              ),
            );
          }

          return BlocBuilder<ProductBloc, ProductState>(
            builder: (context, productState) {
              final allProducts = productState is ProductLoaded
                  ? productState.products
                  : [];

              return SizedBox(
                height: 190,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingL,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: vendors.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: AppDimensions.spacingM),
                  itemBuilder: (context, index) {
                    final vendor = vendors[index];
                    final productCount = allProducts
                        .where((p) => p.farmerId == vendor.id)
                        .length;

                    return InkWell(
                      onTap: () {
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
                                builder: (context) =>
                                    VendorProductsBottomSheet(vendor: vendor),
                              );
                            },
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusL,
                      ),
                      child: Container(
                        width: 170,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusL,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Container(
                                  height: 105,
                                  decoration: BoxDecoration(
                                    color: AppColors.borderLight,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(
                                        AppDimensions.radiusL,
                                      ),
                                    ),
                                    image: vendor.profilePictureUrl != null
                                        ? DecorationImage(
                                            image: CachedNetworkImageProvider(
                                              vendor.profilePictureUrl!,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: vendor.profilePictureUrl == null
                                      ? const Center(
                                          child: Icon(
                                            Icons.store,
                                            color: AppColors.textSecondary,
                                            size: 40,
                                          ),
                                        )
                                      : null,
                                ),
                                if (vendor.isNew)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.2,
                                            ),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        'NEW',
                                        style: AppTextStyles.caption.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(
                                AppDimensions.paddingM,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vendor.businessInfo?.farmName ??
                                        vendor.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.body2.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 2),
                                      Expanded(
                                        child: Text(
                                          'Local Farmer', // Could calculate distance if we had coords
                                          style: AppTextStyles.caption,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '$productCount Products',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPopularProductsList(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) {
          return SkeletonLoaders.horizontalList(
            cardBuilder: SkeletonLoaders.productCard,
            height: 230,
            itemCount: 3,
          );
        }

        if (state is ProductLoaded) {
          // Shuffle or pick popular. For now take first 5.
          final products = state.products.take(5).toList();
          if (products.isEmpty) {
            return EmptyStateWidget.noProducts();
          }

          return SizedBox(
            height: 230,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingL,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppDimensions.spacingM),
              itemBuilder: (context, index) {
                final product = products[index];
                return InkWell(
                  onTap: () {
                    HapticService.selection();
                    final heroTag = 'home_product_${product.id}';
                    context.push(
                      '/product-detail',
                      extra: {'product': product, 'heroTag': heroTag},
                    );
                  },
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  child: Container(
                    width: 160,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusL,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProductImage(
                          product: product,
                          height: 120,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppDimensions.radiusL),
                          ),
                          useHero: true,
                          heroTag: 'home_product_${product.id}',
                          showStockBadge: false,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppDimensions.paddingS),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (product.isOutOfStock) ...[
                                    _buildStatusBadge('Out', AppColors.error),
                                    const SizedBox(width: 4),
                                  ] else if (product.isLowStock) ...[
                                    _buildStatusBadge('Low', AppColors.warning),
                                    const SizedBox(width: 4),
                                  ],
                                  Expanded(
                                    child: Text(
                                      product.category.displayName,
                                      style: AppTextStyles.caption.copyWith(
                                        fontSize: 10,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.body2.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'by ${product.farmerName}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                product.formattedPrice,
                                style: AppTextStyles.body2.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
