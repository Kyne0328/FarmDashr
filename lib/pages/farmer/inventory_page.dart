import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Core constants
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';

// Data models
import 'package:farmdashr/data/models/product.dart';

// BLoC
import 'package:farmdashr/blocs/product/product.dart';

// Shared widgets
import 'package:farmdashr/presentation/widgets/common/stat_card.dart';
import 'package:farmdashr/presentation/widgets/common/status_badge.dart';

/// Inventory Page - using BLoC for state management.
class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading || state is ProductInitial) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ProductError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: AppTextStyles.body1),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<ProductBloc>().add(const LoadProducts()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is ProductLoaded) {
          final products = state.displayProducts;
          final lowStockCount = state.lowStockCount;

          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        context.read<ProductBloc>().add(const LoadProducts());
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppDimensions.paddingL),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Section
                            _buildHeader(context),
                            const SizedBox(height: AppDimensions.spacingL),

                            // Low Stock Alert
                            if (lowStockCount > 0) ...[
                              _LowStockAlert(count: lowStockCount),
                              const SizedBox(height: AppDimensions.spacingL),
                            ],

                            // Stats Grid - using shared StatCard
                            _buildStatsGrid(state),
                            const SizedBox(height: AppDimensions.spacingXL),

                            // Product List
                            _buildProductList(products),
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

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Inventory', style: AppTextStyles.h3),
        GestureDetector(
          onTap: () => context.push('/add-product'),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingL,
              vertical: AppDimensions.paddingM,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add,
                  size: AppDimensions.iconS,
                  color: Colors.white,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text('Add Product', style: AppTextStyles.button),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(ProductLoaded state) {
    final products = state.products;
    final totalRevenue = state.totalRevenue;
    final totalSold = state.totalSold;
    final lowStockCount = state.lowStockCount;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.inventory_2_outlined,
                title: 'Total Products',
                value: '${products.length}',
              ),
            ),
            const SizedBox(width: AppDimensions.spacingL),
            Expanded(
              child: StatCard(
                icon: Icons.warning_amber_rounded,
                title: 'Low Stock',
                value: '$lowStockCount',
                theme: const WarningStatCardTheme(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingL),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.attach_money,
                title: 'Total Revenue',
                value: '\$${totalRevenue.toStringAsFixed(2)}',
              ),
            ),
            const SizedBox(width: AppDimensions.spacingL),
            Expanded(
              child: StatCard(
                icon: Icons.shopping_cart_outlined,
                title: 'Items Sold',
                value: '$totalSold',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductList(List<Product> products) {
    return Column(
      children: products.map((product) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
          child: _ProductCard(product: product),
        );
      }).toList(),
    );
  }
}

// Private widgets

class _LowStockAlert extends StatelessWidget {
  final int count;

  const _LowStockAlert({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingXL),
      decoration: BoxDecoration(
        color: AppColors.warningBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(
          color: AppColors.warningLight,
          width: AppDimensions.borderWidthThick,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: AppDimensions.iconM,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Low Stock Alert',
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.warningText,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  '$count products below minimum stock level',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.warningDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = product.isLowStock
        ? AppColors.warningBackground
        : AppColors.surface;
    final borderColor = product.isLowStock
        ? AppColors.warningLight
        : AppColors.border;
    final stockColor = product.isLowStock
        ? AppColors.warning
        : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingXL),
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
          // Product Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(product.name, style: AppTextStyles.body1),
                        if (product.isLowStock) ...[
                          const SizedBox(width: AppDimensions.spacingS),
                          StatusBadge.lowStock(),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      'SKU: ${product.sku}',
                      style: AppTextStyles.body2Secondary,
                    ),
                  ],
                ),
              ),
              _MoreOptionsButton(),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),

          // Product Stats Row
          Row(
            children: [
              Expanded(
                child: _ProductStat(
                  label: 'Stock',
                  value: product.stockDisplay,
                  valueColor: stockColor,
                ),
              ),
              Expanded(
                child: _ProductStat(
                  label: 'Price',
                  value: product.formattedPrice,
                  valueColor: AppColors.textPrimary,
                ),
              ),
              Expanded(
                child: _ProductStat(
                  label: 'Sold',
                  value: '${product.sold}',
                  valueColor: AppColors.textPrimary,
                  showTrendIcon: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),

          // Revenue Section
          Container(
            padding: const EdgeInsets.only(top: AppDimensions.spacingM),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1.14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Revenue', style: AppTextStyles.body2Tertiary),
                Text(
                  product.formattedRevenue,
                  style: AppTextStyles.body1.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreOptionsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Show product options menu
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: const Icon(
          Icons.more_vert,
          size: AppDimensions.iconS,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ProductStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool showTrendIcon;

  const _ProductStat({
    required this.label,
    required this.value,
    required this.valueColor,
    this.showTrendIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: AppDimensions.spacingXS),
        Row(
          children: [
            Text(value, style: AppTextStyles.body2.copyWith(color: valueColor)),
            if (showTrendIcon) ...[
              const SizedBox(width: AppDimensions.spacingXS),
              Icon(
                Icons.trending_up,
                size: AppDimensions.iconXS,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
