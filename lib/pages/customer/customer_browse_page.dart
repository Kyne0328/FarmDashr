import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/presentation/widgets/common/empty_state_widget.dart';
import 'package:farmdashr/presentation/widgets/common/product_image.dart';
import 'package:farmdashr/presentation/widgets/common/shimmer_loader.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/blocs/product/product.dart';
import 'package:farmdashr/blocs/vendor/vendor.dart';
import 'package:farmdashr/blocs/auth/auth.dart';
import 'package:farmdashr/data/models/product/product.dart';
import 'package:farmdashr/presentation/extensions/product_category_extension.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/services/haptic_service.dart';
import 'package:farmdashr/presentation/widgets/vendor_details_bottom_sheet.dart';
import 'package:farmdashr/presentation/widgets/vendor_products_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:farmdashr/presentation/widgets/common/farm_button.dart';
import 'package:farmdashr/presentation/widgets/common/farm_text_field.dart';
import 'package:farmdashr/core/utils/responsive.dart';

class CustomerBrowsePage extends StatefulWidget {
  final ProductCategory? initialCategory;
  final int initialTabIndex;
  final String? initialSearchQuery;

  const CustomerBrowsePage({
    super.key,
    this.initialCategory,
    this.initialTabIndex = 0,
    this.initialSearchQuery,
  });

  @override
  State<CustomerBrowsePage> createState() => _CustomerBrowsePageState();
}

class _CustomerBrowsePageState extends State<CustomerBrowsePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ProductCategory? _selectedCategory;
  String _searchQuery = '';
  int _currentTabIndex = 0;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(_onTabChanged);
    _selectedCategory = widget.initialCategory;

    // Initialize search query if passed from home page
    if (widget.initialSearchQuery != null &&
        widget.initialSearchQuery!.isNotEmpty) {
      _searchQuery = widget.initialSearchQuery!;
      // Trigger initial search
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ProductBloc>().add(SearchProducts(_searchQuery));
        context.read<VendorBloc>().add(SearchVendors(_searchQuery));
      });
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _currentTabIndex = _tabController.index;
      // Clear category filter and hide filters when switching to Vendors
      if (_currentTabIndex == 1) {
        _selectedCategory = null;
        _showFilters = false;
      }
    });
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onCategorySelected(ProductCategory? category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _searchQuery = '';
    });
    context.read<ProductBloc>().add(const SearchProducts(''));
    context.read<VendorBloc>().add(const SearchVendors(''));
  }

  bool get _hasActiveFilters =>
      _selectedCategory != null || _searchQuery.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            // Only show category chips on Products tab when filter is toggled
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: (_currentTabIndex == 0 && _showFilters)
                  ? _buildCategoryChips()
                  : const SizedBox.shrink(),
            ),
            if (_hasActiveFilters && _currentTabIndex == 0)
              _buildActiveFiltersBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ProductsList(
                    selectedCategory: _selectedCategory,
                    searchQuery: _searchQuery,
                  ),
                  _VendorsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.maxContentWidth(context),
        ),
        child: Container(
          padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
          decoration: BoxDecoration(
            color: AppColors.background,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Browse',
                    style: AppTextStyles.h2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (_hasActiveFilters)
                    SizedBox(
                      width: 80,
                      child: FarmButton(
                        label: 'Clear',
                        icon: Icons.refresh,
                        onPressed: _clearFilters,
                        style: FarmButtonStyle.ghost,
                        textColor: AppColors.textSecondary,
                        height: 32,
                        textSize: 12,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingM),
              // Search bar with Filters button
              Row(
                children: [
                  Expanded(
                    child: _EnhancedSearchBar(
                      onSearchChanged: _onSearchChanged,
                      onClear: () => _onSearchChanged(''),
                    ),
                  ),
                  // Only show filters button on Products tab
                  if (_currentTabIndex == 0) ...[
                    const SizedBox(width: AppDimensions.spacingS),
                    _buildFiltersButton(),
                  ],
                ],
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Container(
                height: 44,
                padding: const EdgeInsets.all(AppDimensions.paddingXS),
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: TabBar(
                  controller: _tabController,
                  padding: EdgeInsets.zero,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textTertiary,
                  labelStyle: AppTextStyles.tabLabelActive,
                  tabs: const [
                    Tab(text: 'Products'),
                    Tab(text: 'Vendors'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersButton() {
    final hasActiveCategory = _selectedCategory != null;

    return GestureDetector(
      onTap: _toggleFilters,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _showFilters || hasActiveCategory
              ? AppColors.primary
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(
            color: _showFilters || hasActiveCategory
                ? AppColors.primary
                : AppColors.border,
          ),
          boxShadow: _showFilters
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.tune_rounded,
              color: _showFilters || hasActiveCategory
                  ? Colors.white
                  : AppColors.textSecondary,
              size: 22,
            ),
            // Show badge when category filter is active
            if (hasActiveCategory && !_showFilters)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = <Map<String, Object?>>[
      {'name': 'Fruits', 'icon': '🍎', 'category': ProductCategory.fruits},
      {
        'name': 'Vegetables',
        'icon': '🥕',
        'category': ProductCategory.vegetables,
      },
      {'name': 'Bakery', 'icon': '🍞', 'category': ProductCategory.bakery},
      {'name': 'Dairy', 'icon': '🥚', 'category': ProductCategory.dairy},
      {'name': 'Meat', 'icon': '🥩', 'category': ProductCategory.meat},
      {'name': 'Other', 'icon': '📦', 'category': ProductCategory.other},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingL,
        vertical: AppDimensions.paddingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Wrap(
        spacing: AppDimensions.spacingS,
        runSpacing: AppDimensions.spacingS,
        children: categories.map((cat) {
          final category = cat['category'] as ProductCategory?;
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () {
              HapticService.selection();
              _onCategorySelected(isSelected ? null : category);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
                vertical: AppDimensions.paddingS,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cat['icon'] as String,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: AppDimensions.spacingXS),
                  Text(
                    cat['name'] as String,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveFiltersBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingL,
        vertical: AppDimensions.paddingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: AppDimensions.spacingS),
          Text(
            'Filtering: ',
            style: AppTextStyles.caption.copyWith(color: AppColors.primary),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_selectedCategory != null)
                    _buildFilterTag(
                      _selectedCategory!.displayName,
                      () => _onCategorySelected(null),
                    ),
                  if (_searchQuery.isNotEmpty) ...[
                    if (_selectedCategory != null)
                      const SizedBox(width: AppDimensions.spacingXS),
                    _buildFilterTag('"$_searchQuery"', () {
                      _onSearchChanged('');
                      context.read<ProductBloc>().add(const SearchProducts(''));
                      context.read<VendorBloc>().add(const SearchVendors(''));
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTag(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingS,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: AppColors.primaryDark),
          ),
        ],
      ),
    );
  }
}

class _EnhancedSearchBar extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClear;

  const _EnhancedSearchBar({
    required this.onSearchChanged,
    required this.onClear,
  });

  @override
  State<_EnhancedSearchBar> createState() => _EnhancedSearchBarState();
}

class _EnhancedSearchBarState extends State<_EnhancedSearchBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  Timer? _debounce;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        widget.onSearchChanged(query);
        context.read<ProductBloc>().add(SearchProducts(query));
        context.read<VendorBloc>().add(SearchVendors(query));
      }
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: FarmTextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onChanged,
        hint: 'Search products, vendors, categories...',
        prefixIcon: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            Icons.search_rounded,
            color: _isFocused ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded),
                color: AppColors.textSecondary,
                onPressed: () {
                  _controller.clear();
                  context.read<ProductBloc>().add(const SearchProducts(''));
                  context.read<VendorBloc>().add(const SearchVendors(''));
                  widget.onClear();
                  setState(() {});
                },
              )
            : null,
      ),
    );
  }
}

// Legacy search bar removed - replaced by _EnhancedSearchBar

class _ProductsList extends StatelessWidget {
  final ProductCategory? selectedCategory;
  final String searchQuery;

  const _ProductsList({this.selectedCategory, this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    // Ensure products are loaded and not filtered by a specific farmer (unless we purposefully chose a vendor)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthBloc>().state.userId;
      final state = context.read<ProductBloc>().state;
      if (state is ProductInitial ||
          state.farmerId != null ||
          state.excludeFarmerId != userId) {
        context.read<ProductBloc>().add(LoadProducts(excludeFarmerId: userId));
      }
    });

    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) {
          return SkeletonLoaders.verticalList(
            cardBuilder: SkeletonLoaders.listItem,
            itemCount: 4,
          );
        }

        if (state is ProductError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingXXL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: AppDimensions.iconXL,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  Text('Failed to load products', style: AppTextStyles.h3),
                  const SizedBox(height: AppDimensions.spacingS),
                  Text(
                    state.message,
                    style: AppTextStyles.body2Secondary,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (state is ProductLoaded) {
          var products = state.displayProducts;

          // Apply category filter if set
          if (selectedCategory != null) {
            products = products
                .where((p) => p.category == selectedCategory)
                .toList();
          }

          if (products.isEmpty) {
            return _buildEmptyState(state);
          }

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive.maxContentWidth(context),
              ),
              child: ListView.separated(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.horizontalPadding(context),
                  vertical: AppDimensions.paddingM,
                ),
                itemCount: products.length,
                separatorBuilder: (ctx, index) =>
                    const SizedBox(height: AppDimensions.spacingM),
                itemBuilder: (ctx, index) {
                  return _ProductListItem(product: products[index]);
                },
              ),
            ),
          );
        }

        // Initial state - trigger load
        return SkeletonLoaders.verticalList(
          cardBuilder: SkeletonLoaders.listItem,
          itemCount: 4,
        );
      },
    );
  }

  Widget _buildEmptyState(ProductLoaded state) {
    return EmptyStateWidget.noProducts(
      searchQuery: state.searchQuery,
      categoryName: selectedCategory?.displayName,
    );
  }
}

class _ProductListItem extends StatelessWidget {
  final Product product;

  const _ProductListItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticService.selection();
        final heroTag = 'browse_product_${product.id}';
        context.push(
          '/product-detail',
          extra: {'product': product, 'heroTag': heroTag},
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ProductImage(
              product: product,
              width: 80,
              height: 80,
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              useHero: true,
              heroTag: 'browse_product_${product.id}',
              showStockBadge: false,
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: AppTextStyles.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (product.isOutOfStock) ...[
                        const SizedBox(width: AppDimensions.spacingS),
                        _buildStatusBadge('Out of Stock', AppColors.error),
                      ] else if (product.isLowStock) ...[
                        const SizedBox(width: AppDimensions.spacingS),
                        _buildStatusBadge('Low Stock', AppColors.warning),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(product.farmerName, style: AppTextStyles.body2Secondary),
                  const SizedBox(height: AppDimensions.spacingS),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.formattedPrice,
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.customerPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingS,
                          vertical: AppDimensions.paddingXS,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.category.displayName,
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

class _VendorsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Ensure vendors are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthBloc>().state.userId;
      final state = context.read<VendorBloc>().state;

      String? currentExcludeId;
      if (state is VendorLoading) {
        currentExcludeId = state.excludeUserId;
      } else if (state is VendorLoaded) {
        currentExcludeId = state.excludeUserId;
      }

      // Pass the userId to exclude it from the list
      // Reload if initial, error, or if exclusion ID doesn't match
      if (state is VendorInitial ||
          state is VendorError ||
          currentExcludeId != userId) {
        context.read<VendorBloc>().add(LoadVendors(excludeUserId: userId));
      }
    });

    return BlocBuilder<VendorBloc, VendorState>(
      builder: (context, state) {
        if (state is VendorInitial) {
          return SkeletonLoaders.verticalList(
            cardBuilder: SkeletonLoaders.listItem,
            itemCount: 4,
          );
        }

        if (state is VendorLoading) {
          return SkeletonLoaders.verticalList(
            cardBuilder: SkeletonLoaders.listItem,
            itemCount: 4,
          );
        }

        if (state is VendorError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingXXL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: AppDimensions.iconXL,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  Text('Failed to load vendors', style: AppTextStyles.h3),
                  const SizedBox(height: AppDimensions.spacingS),
                  Text(
                    state.message,
                    style: AppTextStyles.body2Secondary,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (state is VendorLoaded) {
          final vendors = state.displayVendors;

          if (vendors.isEmpty) {
            return EmptyStateWidget.noVendors(searchQuery: state.searchQuery);
          }

          return BlocBuilder<ProductBloc, ProductState>(
            builder: (context, productState) {
              final allProducts = productState is ProductLoaded
                  ? productState.products
                  : [];

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: Responsive.maxContentWidth(context),
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.horizontalPadding(context),
                      vertical: AppDimensions.paddingS,
                    ),
                    itemCount: vendors.length,
                    separatorBuilder: (ctx, index) =>
                        const SizedBox(height: AppDimensions.spacingM),
                    itemBuilder: (ctx, index) {
                      final vendor = vendors[index];
                      final productCount = allProducts
                          .where((p) => p.farmerId == vendor.id)
                          .length;

                      return _VendorListItem(
                        vendor: vendor,
                        productCount: productCount,
                      );
                    },
                  ),
                ),
              );
            },
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _VendorListItem extends StatelessWidget {
  final UserProfile vendor;
  final int productCount;

  const _VendorListItem({required this.vendor, this.productCount = 0});

  @override
  Widget build(BuildContext context) {
    final farmName = vendor.businessInfo?.farmName ?? vendor.name;
    final primaryCertification =
        vendor.businessInfo?.certifications.isNotEmpty == true
        ? vendor.businessInfo!.certifications.first.name
        : 'Local Producer';

    final operatingHours = vendor.businessInfo?.operatingHours;

    return InkWell(
      onTap: () {
        HapticService.selection();
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
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
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
                      ? const Icon(
                          Icons.store_rounded,
                          size: 32,
                          color: AppColors.textTertiary,
                        )
                      : null,
                ),
                if (vendor.isNew)
                  Positioned(
                    top: -6,
                    left: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusS,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'NEW',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 8,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farmName,
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.local_offer_outlined,
                        size: 12,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        primaryCertification,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (operatingHours != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            operatingHours,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 12,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$productCount Products',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
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

// Deleted _VendorItem class as it's replaced by UserProfile
