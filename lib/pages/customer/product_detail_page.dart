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
import 'package:farmdashr/presentation/widgets/common/shimmer_loader.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:farmdashr/core/utils/snackbar_helper.dart';

class ProductDetailPage extends StatefulWidget {
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
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _currentImageIndex = 0;
  int _quantity = 1;
  bool _isBuyingNow = false;

  void _incrementQuantity() {
    if (_quantity < product.currentStock) {
      setState(() => _quantity++);
      HapticService.selection();
    } else {
      HapticService.error();
      SnackbarHelper.showInfo(context, 'Maximum available stock reached');
    }
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() => _quantity--);
      HapticService.selection();
    } else {
      HapticService.error();
    }
  }

  Product get product => widget.product;
  bool get isFarmerView => widget.isFarmerView;
  String? get heroTag => widget.heroTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<CartBloc, CartState>(
        listener: (context, state) {
          if (state is CartOperationSuccess) {
            if (_isBuyingNow) {
              context.push('/pre-order-checkout');
              setState(() => _isBuyingNow = false); // Reset flag
            } else {
              SnackbarHelper.showSuccess(
                context,
                state.message,
                actionLabel: 'View Cart',
                onActionPressed: () => context.go('/customer-cart'),
              );
            }
          } else if (state is CartError) {
            SnackbarHelper.showError(context, state.message);
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
    final imageCount = product.imageUrls.length;

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
        background: imageCount > 0
            ? _buildImageCarousel()
            : Hero(
                tag: heroTag ?? 'product_image_${product.id}',
                child: Container(
                  color: AppColors.borderLight,
                  child: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 64,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    final imageCount = product.imageUrls.length;

    return Stack(
      children: [
        // Image PageView
        PageView.builder(
          itemCount: imageCount,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final isFirstImage = index == 0;
            Widget imageWidget = Container(
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                image: DecorationImage(
                  image: CachedNetworkImageProvider(product.imageUrls[index]),
                  fit: BoxFit.cover,
                ),
              ),
            );

            // Only apply Hero to the first image for smooth transition
            if (isFirstImage) {
              imageWidget = Hero(
                tag: heroTag ?? 'product_image_${product.id}',
                child: imageWidget,
              );
            }

            // Wrap in GestureDetector for fullscreen view
            return GestureDetector(
              onTap: () {
                HapticService.selection();
                _openFullscreenViewer(context, index);
              },
              child: imageWidget,
            );
          },
        ),

        // Page Indicators
        if (imageCount > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                imageCount,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentImageIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),

        // Image Counter Badge
        if (imageCount > 1)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentImageIndex + 1}/$imageCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _openFullscreenViewer(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullscreenImageViewer(
            imageUrls: product.imageUrls,
            initialIndex: initialIndex,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
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
                  const SizedBox(height: AppDimensions.spacingXS),
                  InkWell(
                    onTap: _showVendorDetails,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Sold by ${product.farmerName}',
                            style: AppTextStyles.body2Secondary.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
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
          product.description ?? 'No description available.',
          style: product.description == null
              ? AppTextStyles.body2Secondary.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.textTertiary,
                )
              : AppTextStyles.body2Secondary.copyWith(height: 1.5),
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
        // Quantity Selector and Action Buttons
        SizedBox(
          width: double.infinity,
          height: 54,
          child: Row(
            children: [
              // Quantity Selector
              if (!product.isOutOfStock) ...[
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _quantity > 1 ? _decrementQuantity : null,
                        icon: const Icon(Icons.remove),
                        color: AppColors.textPrimary,
                        disabledColor: AppColors.textTertiary.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '$_quantity',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.h3,
                        ),
                      ),
                      IconButton(
                        onPressed: _quantity < product.currentStock
                            ? _incrementQuantity
                            : null,
                        icon: const Icon(Icons.add),
                        color: AppColors.textPrimary,
                        disabledColor: AppColors.textTertiary.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
              ],

              // Add to Cart Button (Secondary)
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed: product.isOutOfStock
                        ? null
                        : () {
                            HapticService.light();
                            setState(() => _isBuyingNow = false);
                            context.read<CartBloc>().add(
                              AddToCart(product, quantity: _quantity),
                            );
                          },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: product.isOutOfStock
                            ? AppColors.stateDisabled
                            : AppColors.info,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusM,
                        ),
                      ),
                    ),
                    child: Text(
                      'Add to Cart',
                      style: AppTextStyles.button.copyWith(
                        color: product.isOutOfStock
                            ? AppColors.textTertiary
                            : AppColors.info,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),

              // Buy Now Button (Primary)
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: product.isOutOfStock
                        ? null
                        : () {
                            HapticService.heavy();
                            setState(() => _isBuyingNow = true);
                            context.read<CartBloc>().add(
                              AddToCart(product, quantity: _quantity),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: product.isOutOfStock
                          ? AppColors.stateDisabled
                          : AppColors.info,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusM,
                        ),
                      ),
                      disabledBackgroundColor: AppColors.stateDisabled,
                      disabledForegroundColor: Colors.white,
                    ),
                    child: const Text('Buy Now', style: AppTextStyles.button),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showVendorDetails() async {
    HapticService.selection();
    try {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.radiusXL),
              topRight: Radius.circular(AppDimensions.radiusXL),
            ),
          ),
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingL),
              SkeletonLoaders.vendorCard(),
            ],
          ),
        ),
      );

      final vendor = await VendorRepository().getVendorById(product.farmerId);

      if (!mounted) return;
      Navigator.pop(context);

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
                builder: (context) => VendorProductsBottomSheet(vendor: vendor),
              );
            },
          ),
        );
      } else {
        SnackbarHelper.showError(context, 'Vendor details not found');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      SnackbarHelper.showError(context, 'Error: ${e.toString()}');
    }
  }
}

/// Fullscreen image viewer with pinch-to-zoom and swipe navigation
class _FullscreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullscreenImageViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<_FullscreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Gesture detector for dismiss on tap outside
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(color: Colors.transparent),
          ),

          // Image PageView with InteractiveViewer for zoom
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrls[index],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              );
            },
          ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: IconButton(
              onPressed: () {
                HapticService.selection();
                Navigator.of(context).pop();
              },
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
              ),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
          ),

          // Image counter
          if (widget.imageUrls.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1}/${widget.imageUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Page indicators at bottom
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 32,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
