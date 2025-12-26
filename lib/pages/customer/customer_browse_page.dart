import 'package:flutter/material.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';

class CustomerBrowsePage extends StatelessWidget {
  const CustomerBrowsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Text(
            'Browse',
            style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w600),
          ),
          bottom: TabBar(
            labelColor: AppColors.info, // Consistency with bottom nav
            unselectedLabelColor: AppColors.textTertiary,
            indicatorColor: AppColors.info,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(text: 'Products'),
              Tab(text: 'Vendors'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: _SearchBar(),
            ),
            Expanded(
              child: TabBarView(children: [_ProductsList(), _VendorsList()]),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search for products or vendors...',
        hintStyle: AppTextStyles.body2Secondary,
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: const BorderSide(color: AppColors.info),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
    );
  }
}

class _ProductsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Mock Data
    final products = [
      _ProductItem(
        name: 'Organic Tomatoes',
        category: 'Vegetables',
        price: 4.99,
        farmName: 'Green Valley Farm',
        imageUrl: 'https://placehold.co/100x100',
      ),
      _ProductItem(
        name: 'Fresh Strawberries',
        category: 'Fruits',
        price: 6.50,
        farmName: 'Berry Bliss',
        imageUrl: 'https://placehold.co/100x100',
      ),
      _ProductItem(
        name: 'Free Range Eggs',
        category: 'Dairy',
        price: 3.49,
        farmName: 'Sunny Side Up',
        imageUrl: 'https://placehold.co/100x100',
      ),
      _ProductItem(
        name: 'Artisan Bread',
        category: 'Bakery',
        price: 5.00,
        farmName: 'Golden Wheat',
        imageUrl: 'https://placehold.co/100x100',
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingL,
        vertical: AppDimensions.paddingS,
      ),
      itemCount: products.length,
      separatorBuilder: (ctx, index) =>
          const SizedBox(height: AppDimensions.spacingM),
      itemBuilder: (ctx, index) {
        return _ProductListItem(product: products[index]);
      },
    );
  }
}

class _ProductListItem extends StatelessWidget {
  final _ProductItem product;

  const _ProductListItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              image: DecorationImage(
                image: NetworkImage(product.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: AppTextStyles.h3),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(product.farmName, style: AppTextStyles.body2Secondary),
                const SizedBox(height: AppDimensions.spacingS),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₱${product.price.toStringAsFixed(2)}',
                      style: AppTextStyles.h3.copyWith(color: AppColors.info),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingS,
                        vertical: AppDimensions.paddingXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(
                          6,
                        ), // custom small radius
                      ),
                      child: Text(
                        product.category,
                        style: AppTextStyles.captionPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VendorsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Mock Data
    final vendors = [
      _VendorItem(
        name: 'Green Valley Farm',
        category: 'Organic Produce',
        rating: 4.8,
        reviews: 124,
        distance: '15 miles away',
        imageUrl: 'https://placehold.co/80x80',
      ),
      _VendorItem(
        name: 'Berry Bliss',
        category: 'Berries & Fruits',
        rating: 4.9,
        reviews: 89,
        distance: '8 miles away',
        imageUrl: 'https://placehold.co/80x80',
      ),
      _VendorItem(
        name: 'Sunny Side Up',
        category: 'Fresh Dairy',
        rating: 4.7,
        reviews: 56,
        distance: '12 miles away',
        imageUrl: 'https://placehold.co/80x80',
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingL,
        vertical: AppDimensions.paddingS,
      ),
      itemCount: vendors.length,
      separatorBuilder: (ctx, index) =>
          const SizedBox(height: AppDimensions.spacingM),
      itemBuilder: (ctx, index) {
        return _VendorListItem(vendor: vendors[index]);
      },
    );
  }
}

class _VendorListItem extends StatelessWidget {
  final _VendorItem vendor;

  const _VendorListItem({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              image: DecorationImage(
                image: NetworkImage(vendor.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vendor.name, style: AppTextStyles.h3),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(vendor.category, style: AppTextStyles.body2Secondary),
                const SizedBox(height: AppDimensions.spacingS),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: AppDimensions.iconS,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: AppDimensions.spacingXS),
                    Text(
                      '${vendor.rating} (${vendor.reviews})',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(width: AppDimensions.spacingM),
                    const Icon(
                      Icons.location_on,
                      size: AppDimensions.iconS,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppDimensions.spacingXS),
                    Text(vendor.distance, style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Data Models for UI
class _ProductItem {
  final String name;
  final String category;
  final double price;
  final String farmName;
  final String imageUrl;

  _ProductItem({
    required this.name,
    required this.category,
    required this.price,
    required this.farmName,
    required this.imageUrl,
  });
}

class _VendorItem {
  final String name;
  final String category;
  final double rating;
  final int reviews;
  final String distance;
  final String imageUrl;

  _VendorItem({
    required this.name,
    required this.category,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.imageUrl,
  });
}
