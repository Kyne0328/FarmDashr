import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Core constants
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';

// Data models
import 'package:farmdashr/data/models/product/product.dart';

// BLoC
import 'package:farmdashr/core/utils/snackbar_helper.dart';
import 'package:farmdashr/core/services/haptic_service.dart';
import 'package:farmdashr/blocs/product/product.dart';
import 'package:farmdashr/blocs/auth/auth.dart';

// Shared widgets
import 'package:farmdashr/presentation/widgets/common/stat_card.dart';
import 'package:farmdashr/presentation/widgets/common/status_badge.dart';
import 'package:farmdashr/presentation/widgets/common/empty_state_widget.dart';
import 'package:farmdashr/presentation/widgets/common/product_image.dart';
import 'package:farmdashr/presentation/widgets/common/shimmer_loader.dart';
import 'package:farmdashr/presentation/widgets/common/farm_button.dart';

/// Inventory Page - using BLoC for state management.
class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage>
    with SingleTickerProviderStateMixin {
  /// Staggered animations for page sections
  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Staggered animations: Header, Low Stock Alert, Stats, Product List
    _fadeAnimations = List.generate(4, (index) {
      final start = index * 0.15;
      final end = start + 0.4;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            start.clamp(0.0, 1.0),
            end.clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      );
    });

    _slideAnimations = List.generate(4, (index) {
      final start = index * 0.15;
      final end = start + 0.4;
      return Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            start.clamp(0.0, 1.0),
            end.clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedSection(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(position: _slideAnimations[index], child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final userId = authState.userId;

        if (!authState.isAuthenticated) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            // If the state is initial or the farmerId in state doesn't match current userId, reload
            if (state is ProductInitial ||
                (state.farmerId != userId && userId != null)) {
              context.read<ProductBloc>().add(LoadProducts(farmerId: userId));
              return _buildLoadingScreen();
            }

            if (state is ProductLoading) {
              return _buildLoadingScreen();
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
                        onPressed: () => context.read<ProductBloc>().add(
                          LoadProducts(farmerId: userId),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is ProductDataState) {
              return _buildLoadedScreen(context, state, userId);
            }

            return _buildLoadingScreen();
          },
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            children: [
              SkeletonLoaders.inventoryCard(),
              const SizedBox(height: AppDimensions.spacingM),
              SkeletonLoaders.inventoryCard(),
              const SizedBox(height: AppDimensions.spacingM),
              SkeletonLoaders.inventoryCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedScreen(
    BuildContext context,
    ProductDataState state,
    String? userId,
  ) {
    final products = state is ProductLoaded
        ? state.displayProducts
        : state.products;
    final lowStockCount = state.lowStockCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<ProductBloc>().add(
                    LoadProducts(farmerId: userId),
                  );
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      _buildAnimatedSection(0, _buildHeader(context)),
                      const SizedBox(height: AppDimensions.spacingL),

                      // Low Stock Alert
                      if (lowStockCount > 0) ...[
                        _buildAnimatedSection(
                          1,
                          _LowStockAlert(count: lowStockCount),
                        ),
                        const SizedBox(height: AppDimensions.spacingL),
                      ],

                      // Stats Grid - using shared StatCard
                      _buildAnimatedSection(2, _buildStatsGrid(state)),
                      const SizedBox(height: AppDimensions.spacingXL),

                      // Product List
                      _buildAnimatedSection(
                        3,
                        products.isEmpty
                            ? _buildEmptyState(context)
                            : _buildProductList(products),
                      ),
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

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateWidget.emptyInventory(
      onAddProduct: () => context.push('/add-product'),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Inventory',
            style: AppTextStyles.h3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        IntrinsicWidth(
          child: FarmButton(
            label: 'Add Product',
            icon: Icons.add,
            onPressed: () {
              HapticService.selection();
              context.push('/add-product');
            },
            style: FarmButtonStyle.primary,
            height: 44,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(ProductDataState state) {
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
                value: '₱${totalRevenue.toStringAsFixed(2)}',
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
      children: products.asMap().entries.map((entry) {
        final index = entry.key;
        final product = entry.value;
        // Staggered animation for each product card
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 80)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
            child: _ProductCard(product: product),
          ),
        );
      }).toList(),
    );
  }
}

// Private widgets

/// Low Stock Alert with shake animation
class _LowStockAlert extends StatefulWidget {
  final int count;

  const _LowStockAlert({required this.count});

  @override
  State<_LowStockAlert> createState() => _LowStockAlertState();
}

class _LowStockAlertState extends State<_LowStockAlert>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Play shake animation after a short delay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _shakeController.forward().then((_) {
          if (mounted) {
            _shakeController.reverse();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        // Create a shake effect using sine wave
        final shakeOffset = math.sin(_shakeAnimation.value * math.pi * 4) * 3;
        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: child,
        );
      },
      child: Container(
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
            // Animated warning icon with pulse effect
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: 1.15),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Icon(
                Icons.warning_amber_rounded,
                size: AppDimensions.iconM,
                color: AppColors.warning,
              ),
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
                    '${widget.count} products below minimum stock level',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.warningDark,
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

/// Product Card with press animation
class _ProductCard extends StatefulWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _pressController.forward();

  void _onTapUp(TapUpDetails details) {
    _pressController.reverse();
    HapticService.selection();
    context.push(
      '/product-detail',
      extra: {'product': widget.product, 'isFarmerView': true},
    );
  }

  void _onTapCancel() => _pressController.reverse();

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final backgroundColor = product.isLowStock
        ? AppColors.warningBackground
        : AppColors.surface;
    final borderColor = product.isLowStock
        ? AppColors.warningLight
        : AppColors.border;
    final stockColor = product.isLowStock
        ? AppColors.warning
        : AppColors.textPrimary;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.all(AppDimensions.paddingXL),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
            border: Border.all(
              color: borderColor,
              width: AppDimensions.borderWidthThick,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image and Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  ProductImage(
                    product: product,
                    width: 60,
                    height: 60,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    showStockBadge: false,
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  // Product Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                product.name,
                                style: AppTextStyles.body1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (product.isOutOfStock) ...[
                              const SizedBox(width: AppDimensions.spacingS),
                              _buildStatusBadge(
                                'Out of Stock',
                                AppColors.error,
                              ),
                            ] else if (product.isLowStock) ...[
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
                  _MoreOptionsButton(product: product),
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
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MoreOptionsButton extends StatelessWidget {
  final Product product;

  const _MoreOptionsButton({required this.product});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: const Icon(
        Icons.more_vert,
        size: AppDimensions.iconS,
        color: AppColors.textSecondary,
      ),
      onSelected: (value) {
        if (value == 'edit') {
          context.push('/add-product', extra: product);
        } else if (value == 'delete') {
          _showDeleteConfirmation(context);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 20),
              SizedBox(width: 8),
              Text('Edit Product'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 20, color: AppColors.error),
              SizedBox(width: 8),
              Text('Delete Product', style: AppTextStyles.actionDestructive),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          SizedBox(
            width: 80,
            child: FarmButton(
              label: 'Cancel',
              onPressed: () => Navigator.pop(dialogContext),
              style: FarmButtonStyle.ghost,
              textColor: AppColors.textSecondary,
              height: 40,
            ),
          ),
          SizedBox(
            width: 80,
            child: FarmButton(
              label: 'Delete',
              onPressed: () {
                context.read<ProductBloc>().add(DeleteProduct(product.id));
                Navigator.pop(dialogContext);
                SnackbarHelper.showSuccess(context, '${product.name} deleted');
              },
              style: FarmButtonStyle.danger,
              height: 40,
            ),
          ),
        ],
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
