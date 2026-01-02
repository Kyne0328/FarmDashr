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
import 'package:farmdashr/data/models/product.dart';
import 'package:go_router/go_router.dart';

class CustomerHomePage extends StatelessWidget {
  const CustomerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildSearchBar(context),
              const SizedBox(height: AppDimensions.spacingXL),
              _buildSectionHeader(
                'Explore Categories',
                onSeeAll: () => context.go('/customer-browse'),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              _buildCategoriesList(context),
              const SizedBox(height: AppDimensions.spacingXL),

              _buildSectionHeader(
                'Featured Vendors',
                onSeeAll: () {
                  // Navigate to browse and switch to vendors tab if possible
                  // For now, just navigate to browse
                  context.go('/customer-browse');
                },
              ),
              const SizedBox(height: AppDimensions.spacingM),
              _buildFeaturedVendorsList(),
              const SizedBox(height: AppDimensions.spacingXL),

              // Popular Products
              _buildSectionHeader(
                'Popular This Week',
                onSeeAll: () => context.go('/customer-browse'),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              _buildPopularProductsList(context),
              const SizedBox(height: AppDimensions.spacingXL),
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
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.info.withValues(alpha: 0.05),
                AppColors.background,
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hello, $name! 👋', style: AppTextStyles.h1),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    'What would you like today?',
                    style: AppTextStyles.subtitle.copyWith(fontSize: 14),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => context.push('/customer-profile'),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: state.profilePictureUrl != null
                      ? NetworkImage(state.profilePictureUrl!)
                      : null,
                  child: state.profilePictureUrl == null
                      ? const Icon(
                          Icons.person_outline,
                          color: AppColors.primary,
                        )
                      : null,
                ),
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
      child: GestureDetector(
        onTap: () => context.go('/customer-browse'),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingL,
            vertical: AppDimensions.paddingM,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.textSecondary),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                'Search for products, vendors...',
                style: AppTextStyles.body2Secondary.copyWith(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required VoidCallback onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.h2),
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              'See All',
              style: AppTextStyles.link.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList(BuildContext context) {
    final categories = [
      {'name': 'Fruits', 'icon': '🍎', 'category': ProductCategory.fruits},
      {'name': 'Veggies', 'icon': '🥕', 'category': ProductCategory.vegetables},
      {'name': 'Bakery', 'icon': '🍞', 'category': ProductCategory.bakery},
      {'name': 'Dairy', 'icon': '🥚', 'category': ProductCategory.dairy},
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppDimensions.spacingM),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return InkWell(
            onTap: () {
              // For now, navigate to browse.
              // Logic to filter by category could be added by passing extra data to /browse
              context.go('/customer-browse');
            },
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            child: Container(
              width: 80,
              padding: const EdgeInsets.all(AppDimensions.paddingS),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(cat['icon'] as String, style: AppTextStyles.emoji),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    cat['name'] as String,
                    style: AppTextStyles.captionPrimary.copyWith(
                      fontWeight: FontWeight.w600,
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

  Widget _buildFeaturedVendorsList() {
    return BlocBuilder<VendorBloc, VendorState>(
      builder: (context, state) {
        if (state is VendorInitial) {
          context.read<VendorBloc>().add(const LoadVendors());
        }

        if (state is VendorLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is VendorLoaded) {
          final vendors = state.vendors.take(5).toList(); // Show top 5 featured
          if (vendors.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
              child: Text('No vendors found.'),
            );
          }

          return SizedBox(
            height: 180,
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
                return InkWell(
                  onTap: () {
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
                  },
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  child: Container(
                    width: 160,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusL,
                      ),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.borderLight,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppDimensions.radiusL),
                            ),
                            image: vendor.profilePictureUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(
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
                                  ),
                                )
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppDimensions.paddingS),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vendor.businessInfo?.farmName ?? vendor.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.body2.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppDimensions.spacingXS),
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

  Widget _buildPopularProductsList(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ProductLoaded) {
          final products = state.products
              .take(5)
              .toList(); // Show top 5 popular
          if (products.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
              child: Text('No products found.'),
            );
          }

          return SizedBox(
            height: 220,
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
                    context.push(
                      '/product-detail',
                      extra: {'product': product},
                    );
                  },
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  child: Container(
                    width: 160,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusL,
                      ),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.borderLight,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppDimensions.radiusL),
                            ),
                            image: product.imageUrls.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(
                                      product.imageUrls.first,
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: product.imageUrls.isEmpty
                              ? const Center(
                                  child: Icon(
                                    Icons.shopping_basket,
                                    color: AppColors.textSecondary,
                                  ),
                                )
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppDimensions.paddingS),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                product.farmerName,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppDimensions.spacingXS),
                              Text(
                                product.formattedPrice,
                                style: AppTextStyles.body2.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.info,
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
}
