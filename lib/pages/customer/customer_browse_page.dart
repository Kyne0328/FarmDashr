import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/blocs/product/product.dart';
import 'package:farmdashr/blocs/vendor/vendor.dart';
import 'package:farmdashr/data/models/product.dart';
import 'package:farmdashr/data/models/user_profile.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/presentation/widgets/vendor_details_bottom_sheet.dart';
import 'package:farmdashr/presentation/widgets/vendor_products_bottom_sheet.dart';

class CustomerBrowsePage extends StatefulWidget {
  final ProductCategory? initialCategory;
  final int initialTabIndex;

  const CustomerBrowsePage({
    super.key,
    this.initialCategory,
    this.initialTabIndex = 0,
  });

  @override
  State<CustomerBrowsePage> createState() => _CustomerBrowsePageState();
}

class _CustomerBrowsePageState extends State<CustomerBrowsePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ProductCategory? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
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
            _buildCategoryChips(),
            if (_hasActiveFilters) _buildActiveFiltersBar(),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingL,
        AppDimensions.paddingL,
        AppDimensions.paddingL,
        AppDimensions.paddingS,
      ),
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
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _EnhancedSearchBar(
            onSearchChanged: _onSearchChanged,
            onClear: () => _onSearchChanged(''),
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
                color: AppColors.infoDark,
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
    );
  }

  Widget _buildCategoryChips() {
    final categories = <Map<String, Object?>>[
      {'name': 'All', 'icon': '🛒', 'category': null},
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
      height: 50,
      margin: const EdgeInsets.only(top: AppDimensions.spacingS),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppDimensions.spacingS),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final category = cat['category'] as ProductCategory?;
          final isSelected = _selectedCategory == category;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              avatar: Text(
                cat['icon'] as String,
                style: const TextStyle(fontSize: 16),
              ),
              label: Text(cat['name'] as String),
              labelStyle: AppTextStyles.body2.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingS,
                vertical: AppDimensions.paddingXS,
              ),
              onSelected: (_) =>
                  _onCategorySelected(isSelected ? null : category),
            ),
          );
        },
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
        color: AppColors.infoLight.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: AppColors.info.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list_rounded, size: 16, color: AppColors.info),
          const SizedBox(width: AppDimensions.spacingS),
          Text(
            'Filtering: ',
            style: AppTextStyles.caption.copyWith(color: AppColors.info),
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
        color: AppColors.info.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.infoDark,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: AppColors.infoDark),
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
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onChanged,
        style: AppTextStyles.body1,
        decoration: InputDecoration(
          hintText: 'Search products, vendors, categories...',
          hintStyle: AppTextStyles.body2Secondary,
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
                    widget.onClear();
                    context.read<ProductBloc>().add(const SearchProducts(''));
                    context.read<VendorBloc>().add(const SearchVendors(''));
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            borderSide: BorderSide(
              color: _isFocused ? AppColors.primary : AppColors.border,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingM,
            vertical: AppDimensions.paddingM,
          ),
        ),
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
    // Ensure products are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<ProductBloc>().state;
      if (state is ProductInitial) {
        context.read<ProductBloc>().add(const LoadProducts());
      }
    });

    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
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

          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingL,
              vertical: AppDimensions.paddingM,
            ),
            itemCount: products.length,
            separatorBuilder: (ctx, index) =>
                const SizedBox(height: AppDimensions.spacingM),
            itemBuilder: (ctx, index) {
              return _ProductListItem(product: products[index]);
            },
          );
        }

        // Initial state - trigger load
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      },
    );
  }

  Widget _buildEmptyState(ProductLoaded state) {
    final hasFilters = selectedCategory != null || state.searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilters
                    ? Icons.search_off_rounded
                    : Icons.inventory_2_outlined,
                size: 40,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text(
              _getEmptyTitle(state),
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              _getEmptySubtitle(state),
              style: AppTextStyles.body2Secondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getEmptyTitle(ProductLoaded state) {
    if (selectedCategory != null && state.searchQuery.isNotEmpty) {
      return 'No ${selectedCategory!.displayName} matching "${state.searchQuery}"';
    } else if (selectedCategory != null) {
      return 'No ${selectedCategory!.displayName} available';
    } else if (state.searchQuery.isNotEmpty) {
      return 'No products matching "${state.searchQuery}"';
    }
    return 'No products available';
  }

  String _getEmptySubtitle(ProductLoaded state) {
    if (selectedCategory != null || state.searchQuery.isNotEmpty) {
      return 'Try adjusting your filters or search terms';
    }
    return 'Check back later for fresh produce!';
  }
}

class _ProductListItem extends StatelessWidget {
  final Product product;

  const _ProductListItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/product-detail', extra: {'product': product}),
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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                image: product.imageUrls.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(product.imageUrls.first),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: product.imageUrls.isEmpty
                  ? const Icon(
                      Icons.image_outlined,
                      color: AppColors.textTertiary,
                    )
                  : null,
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: AppTextStyles.h3),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(product.farmerName, style: AppTextStyles.body2Secondary),
                  const SizedBox(height: AppDimensions.spacingS),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.formattedPrice,
                        style: AppTextStyles.h3.copyWith(color: AppColors.info),
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
}

class _VendorsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VendorBloc, VendorState>(
      builder: (context, state) {
        if (state is VendorInitial) {
          context.read<VendorBloc>().add(const LoadVendors());
        }

        if (state is VendorLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state is VendorError) {
          return Center(child: Text(state.message));
        }

        if (state is VendorLoaded) {
          final vendors = state.displayVendors;

          if (vendors.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingXXL),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.store_outlined,
                      size: AppDimensions.iconXL,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: AppDimensions.spacingM),
                    Text(
                      state.searchQuery.isEmpty
                          ? 'No vendors found'
                          : 'No vendors matching "${state.searchQuery}"',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    Text(
                      state.searchQuery.isEmpty
                          ? 'Check back later for more local producers!'
                          : 'Try adjusting your search terms.',
                      style: AppTextStyles.body2Secondary,
                    ),
                  ],
                ),
              ),
            );
          }

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

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _VendorListItem extends StatelessWidget {
  final UserProfile vendor;

  const _VendorListItem({required this.vendor});

  @override
  Widget build(BuildContext context) {
    final farmName = vendor.businessInfo?.farmName ?? vendor.name;
    final category = vendor.businessInfo?.certifications.isNotEmpty == true
        ? vendor.businessInfo!.certifications.first.name
        : 'Local Producer';

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
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                image: vendor.profilePictureUrl != null
                    ? DecorationImage(
                        image: NetworkImage(vendor.profilePictureUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: vendor.profilePictureUrl == null
                  ? const Icon(Icons.store, color: AppColors.textTertiary)
                  : null,
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(farmName, style: AppTextStyles.h3),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(category, style: AppTextStyles.body2Secondary),
                  const SizedBox(height: AppDimensions.spacingS),
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
