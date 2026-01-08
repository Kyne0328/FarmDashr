import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:farmdashr/data/repositories/repositories.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/services/haptic_service.dart';
import 'package:farmdashr/data/models/product/product.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:farmdashr/blocs/product/product.dart';
import 'package:farmdashr/blocs/cart/cart.dart';
import 'package:farmdashr/core/utils/responsive.dart';
import 'package:farmdashr/presentation/widgets/common/farm_button.dart';
import 'package:farmdashr/presentation/widgets/common/status_badge.dart';
import 'package:farmdashr/core/utils/snackbar_helper.dart';
import 'package:farmdashr/presentation/widgets/common/shimmer_loader.dart';
import 'package:farmdashr/presentation/widgets/vendor_details_bottom_sheet.dart';
import 'package:farmdashr/presentation/widgets/vendor_products_bottom_sheet.dart';
import 'package:farmdashr/presentation/extensions/product_category_extension.dart';
import 'package:farmdashr/data/models/cart/cart_item.dart';
import 'package:farmdashr/data/models/auth/pickup_location.dart';
import 'package:farmdashr/presentation/widgets/common/map_display_widget.dart';

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
  late TextEditingController _quantityController;
  final UserRepository _userRepository = FirestoreUserRepository();
  UserProfile? _vendorProfile;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
    _loadVendorProfile();
  }

  Future<void> _loadVendorProfile() async {
    try {
      final profile = await _userRepository.getById(product.farmerId);
      if (profile != null && mounted) {
        setState(() {
          _vendorProfile = profile;
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        ),
        title: Row(
          children: [
            const Icon(Icons.delete_outline, color: AppColors.error),
            const SizedBox(width: AppDimensions.spacingM),
            const Text('Delete Product'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
          style: AppTextStyles.body1,
        ),
        actionsPadding: const EdgeInsets.all(AppDimensions.paddingL),
        actions: [
          Row(
            children: [
              Expanded(
                child: FarmButton(
                  label: 'Cancel',
                  onPressed: () => Navigator.pop(context, false),
                  style: FarmButtonStyle.outline,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: FarmButton(
                  label: 'Delete',
                  onPressed: () => Navigator.pop(context, true),
                  style: FarmButtonStyle.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<ProductBloc>().add(DeleteProduct(product.id));
      SnackbarHelper.showSuccess(context, 'Product deleted');
      context.pop(); // Go back to inventory
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
            final successState = state; // Cast for access
            if (_isBuyingNow) {
              context.push('/pre-order-checkout');
              setState(() => _isBuyingNow = false); // Reset flag
            } else {
              SnackbarHelper.showSuccess(
                context,
                successState.message,
                actionLabel: 'View Cart',
                onActionPressed: () => context.go('/customer-cart'),
              );
            }
          } else if (state is CartError) {
            final errorState = state;
            SnackbarHelper.showError(context, errorState.message);
          }
        },
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.maxContentWidth(context),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(
                      Responsive.horizontalPadding(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProductHeader(),
                        const SizedBox(height: AppDimensions.spacingL),
                        _buildDescription(),
                        const SizedBox(height: AppDimensions.spacingXL),
                        _buildProductDetails(),
                        const SizedBox(height: AppDimensions.spacingXL),
                        if (!isFarmerView) _buildPickupLocationsMap(),
                        if (!isFarmerView)
                          const SizedBox(height: AppDimensions.spacingXL),
                        if (isFarmerView)
                          _buildActionButtons(context), // Only keep for farmer
                        const SizedBox(
                          height: 80,
                        ), // Bottom padding for sticky bar
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isFarmerView ? null : _buildBottomBar(context),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    // Hide bottom bar if keyboard is open
    if (MediaQuery.of(context).viewInsets.bottom > 0) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 80, // Taller to accommodate vertical text
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Vendor (20%)
            Expanded(
              flex: 2,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showVendorDetails,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.storefront,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Store',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Vertical Divider
            Container(width: 1, height: 40, color: AppColors.border),

            // Add to Cart (20%)
            Expanded(
              flex: 2,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: product.isOutOfStock
                      ? null
                      : () => _showQuantityModal(isBuyNow: false),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_shopping_cart,
                        color: product.isOutOfStock
                            ? AppColors.textTertiary
                            : AppColors.customerPrimary,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add to Cart',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          color: product.isOutOfStock
                              ? AppColors.textTertiary
                              : AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Buy Now (60%)
            Expanded(
              flex: 6,
              child: Container(
                height: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingM,
                  vertical: AppDimensions.paddingS,
                ),
                child: FarmButton(
                  label: product.isOutOfStock ? 'Out of Stock' : 'Buy Now',
                  onPressed: product.isOutOfStock
                      ? null
                      : () => _showQuantityModal(isBuyNow: true),
                  style: FarmButtonStyle.primary,
                  backgroundColor: product.isOutOfStock
                      ? AppColors.stateDisabled
                      : AppColors.customerPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuantityModal({required bool isBuyNow}) {
    HapticService.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuantityBottomSheet(
        product: product,
        initialQuantity: _quantity,
        isBuyNow: isBuyNow,
        onConfirm: (qty) {
          Navigator.pop(ctx);
          setState(() {
            _quantity = qty;
          });

          if (isBuyNow) {
            // Buy Now - navigate directly to checkout with just this item
            HapticService.heavy();
            final buyNowItem = CartItem(product: product, quantity: qty);
            context.push('/pre-order-checkout', extra: [buyNowItem]);
          } else {
            // Add to Cart - use the cart bloc
            HapticService.light();
            setState(() => _isBuyingNow = false);
            context.read<CartBloc>().add(AddToCart(product, quantity: qty));
          }
        },
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
        Text(
          product.name,
          style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // Vendor Card
        InkWell(
          onTap: _showVendorDetails,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.farmerPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.storefront,
                    color: AppColors.farmerPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sold by',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      if (_vendorProfile == null)
                        ShimmerBox(width: 120, height: 16, borderRadius: 4)
                      else
                        Text(
                          _vendorProfile?.businessInfo?.farmName ??
                              (product.farmerName.isEmpty
                                  ? 'Unknown Farm'
                                  : product.farmerName),
                          style: AppTextStyles.body2.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppDimensions.spacingL),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              product.formattedPrice,
              style: AppTextStyles.h1.copyWith(
                color: AppColors.customerPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (product.isLowStock) StatusBadge.lowStock(),
          ],
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

  Widget _buildPickupLocationsMap() {
    // Get pickup locations for this product from vendor profile
    final vendorPickupLocations =
        _vendorProfile?.businessInfo?.pickupLocations ?? [];

    // Filter to only locations specified for this product, or all if none specified
    List<PickupLocation> relevantLocations;
    if (product.pickupLocationIds.isEmpty) {
      // Product available at all vendor locations
      relevantLocations = vendorPickupLocations;
    } else {
      // Product only at specific locations
      relevantLocations = vendorPickupLocations
          .where((loc) => product.pickupLocationIds.contains(loc.id))
          .toList();
    }

    // Filter to only locations with GPS coordinates
    final locationsWithCoords = relevantLocations
        .where((loc) => loc.coordinates != null)
        .toList();

    if (locationsWithCoords.isEmpty) {
      // Show list view if no coordinates available
      if (relevantLocations.isEmpty) {
        return const SizedBox.shrink();
      }

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
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('Pickup Locations', style: AppTextStyles.h3),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingM),
            ...relevantLocations.map(
              (loc) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
                child: Row(
                  children: [
                    const Icon(
                      Icons.place,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.name,
                            style: AppTextStyles.body2.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            loc.address,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Show map with locations
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
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Pickup Locations', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            'Tap a marker for directions',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          MapDisplayWidget(
            markers: locationsWithCoords
                .map(
                  (loc) => MapMarkerData(
                    id: loc.id,
                    location: loc.coordinates!,
                    title: loc.name,
                    subtitle: loc.address,
                  ),
                )
                .toList(),
            height: 200,
            showDirectionsButton: true,
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
            child: FarmButton(
              label: 'Edit Product',
              icon: Icons.edit_outlined,
              onPressed: () {
                HapticService.selection();
                context.push('/add-product', extra: product);
              },
              style: FarmButtonStyle.primary,
              height: 54,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          SizedBox(
            width: double.infinity,
            child: FarmButton(
              label: 'Delete Product',
              icon: Icons.delete_outline,
              onPressed: _deleteProduct,
              style: FarmButtonStyle.danger,
              height: 54,
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  void _showVendorDetails() {
    HapticService.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FutureBuilder<UserProfile?>(
        // Note: Assuming UserProfile
        future: context.read<UserRepository>().getById(product.farmerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
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
            );
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Container(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.radiusXL),
                  topRight: Radius.circular(AppDimensions.radiusXL),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 48,
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  Text(
                    'Could not load vendor details',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: AppDimensions.spacingL),
                  FarmButton(
                    label: 'Close',
                    onPressed: () => Navigator.pop(context),
                    style: FarmButtonStyle.outline,
                  ),
                ],
              ),
            );
          }

          final vendor = snapshot.data!;
          return VendorDetailsBottomSheet(
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
          );
        },
      ),
    );
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

class _QuantityBottomSheet extends StatefulWidget {
  final Product product;
  final int initialQuantity;
  final bool isBuyNow;
  final Function(int) onConfirm;

  const _QuantityBottomSheet({
    required this.product,
    required this.initialQuantity,
    required this.isBuyNow,
    required this.onConfirm,
  });

  @override
  State<_QuantityBottomSheet> createState() => _QuantityBottomSheetState();
}

class _QuantityBottomSheetState extends State<_QuantityBottomSheet> {
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
  }

  void _increment() {
    if (_quantity < widget.product.currentStock) {
      setState(() => _quantity++);
      HapticService.selection();
    } else {
      HapticService.error();
    }
  }

  void _decrement() {
    if (_quantity > 1) {
      setState(() => _quantity--);
      HapticService.selection();
    } else {
      HapticService.error();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusXL),
          topRight: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
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

          // Product Preview
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(color: AppColors.border),
                  image: widget.product.imageUrls.isNotEmpty
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(
                            widget.product.imageUrls.first,
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: widget.product.imageUrls.isEmpty
                    ? const Icon(Icons.image, color: AppColors.textTertiary)
                    : null,
              ),
              const SizedBox(width: AppDimensions.spacingM),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.formattedPrice,
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stock: ${widget.product.currentStock}',
                      style: AppTextStyles.body2Secondary,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingL),
          const Divider(),
          const SizedBox(height: AppDimensions.spacingL),

          // Quantity Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Quantity', style: AppTextStyles.h4),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _quantity > 1 ? _decrement : null,
                      icon: const Icon(Icons.remove),
                      color: AppColors.textPrimary,
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '$_quantity',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.h4,
                      ),
                    ),
                    IconButton(
                      onPressed: _quantity < widget.product.currentStock
                          ? _increment
                          : null,
                      icon: const Icon(Icons.add),
                      color: AppColors.textPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingXXL),

          // Confirm Button
          SizedBox(
            width: double.infinity,
            child: FarmButton(
              label: widget.isBuyNow ? 'Buy Now' : 'Add to Cart',
              onPressed: () => widget.onConfirm(_quantity),
              style: FarmButtonStyle.primary,
              backgroundColor: AppColors.primary,
              height: 54,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}
