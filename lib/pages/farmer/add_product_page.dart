import 'package:flutter/material.dart';
import 'package:farmdashr/data/repositories/repositories.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/data/models/product/product.dart';
import 'package:farmdashr/presentation/extensions/product_category_extension.dart';
import 'package:farmdashr/blocs/product/product.dart';
import 'package:farmdashr/blocs/auth/auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

import 'package:farmdashr/data/models/auth/pickup_location.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';

import 'package:farmdashr/presentation/widgets/common/step_indicator.dart';
import 'package:farmdashr/core/utils/snackbar_helper.dart';
import 'package:farmdashr/presentation/widgets/common/farm_button.dart';
import 'package:farmdashr/presentation/widgets/common/farm_text_field.dart';
import 'package:farmdashr/presentation/widgets/common/farm_dropdown.dart';
import 'package:farmdashr/presentation/widgets/common/pickup_location_tile.dart';
import 'package:farmdashr/presentation/widgets/common/map_picker_widget.dart';
import 'package:farmdashr/presentation/widgets/common/map_display_widget.dart';
import 'package:farmdashr/data/models/geo_location.dart';
import 'package:farmdashr/presentation/widgets/common/farm_time_picker.dart';
import 'package:farmdashr/core/utils/validators.dart';

/// Add Product Page - Form to add new products or edit existing ones to inventory.
class AddProductPage extends StatefulWidget {
  final Product? product;

  const AddProductPage({super.key, this.product});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  ProductCategory _selectedCategory = ProductCategory.vegetables;
  bool _isSubmitting = false;

  final List<String> _selectedPickupLocationIds = [];
  List<PickupLocation> _allAvailablePickupLocations = [];
  UserProfile? _userProfile;
  final UserRepository _userRepository = FirestoreUserRepository();

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final List<Uint8List> _imagePreviews = [];
  final List<String> _existingImageUrls = [];

  bool get _isEditing => widget.product != null;

  final PageController _pageController = PageController();
  int _currentStep = 0;
  final List<String> _stepLabels = ['Basic Info', 'Pricing', 'Media', 'Review'];
  bool _showMediaErrors = false;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final p = widget.product!;
      _nameController.text = p.name;
      _skuController.text = p.sku;
      _descriptionController.text = p.description ?? '';
      _priceController.text = p.price.toString();
      _stockController.text = p.currentStock.toString();
      _minStockController.text = p.minStock.toString();
      _selectedCategory = p.category;
      _existingImageUrls.addAll(p.imageUrls);
      _selectedPickupLocationIds.addAll(p.pickupLocationIds);
    }
    _loadUserPickupLocations();
  }

  Future<void> _loadUserPickupLocations() async {
    final authState = context.read<AuthBloc>().state;
    if (authState.userId != null) {
      final profile = await _userRepository.getById(authState.userId!);
      if (profile != null) {
        if (!mounted) return;
        setState(() {
          _userProfile = profile;
          if (profile.businessInfo != null) {
            _allAvailablePickupLocations = List.from(
              profile.businessInfo!.pickupLocations,
            );
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      for (final image in images) {
        final bytes = await image.readAsBytes();
        if (!mounted) return;
        setState(() {
          _selectedImages.add(image);
          _imagePreviews.add(bytes);
        });
      }
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _imagePreviews.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  void _submitProduct() {
    if (!_formKey.currentState!.validate()) return;

    if (_allAvailablePickupLocations.isNotEmpty &&
        _selectedPickupLocationIds.isEmpty) {
      SnackbarHelper.showError(
        context,
        'Please select at least one pickup location.',
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    final userId = authState.userId;

    if (userId == null) {
      SnackbarHelper.showError(context, 'Error: User not authenticated');
      return;
    }

    setState(() => _isSubmitting = true);

    final product = Product(
      id: _isEditing ? widget.product!.id : '',
      farmerId: userId,
      farmerName:
          _userProfile?.businessInfo?.farmName ??
          authState.displayName ??
          'Farmer',
      name: _nameController.text.trim(),
      sku: _skuController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      price: double.tryParse(_priceController.text) ?? 0.0,
      currentStock: int.tryParse(_stockController.text) ?? 0,
      minStock: int.tryParse(_minStockController.text) ?? 10,
      category: _selectedCategory,
      sold: _isEditing ? widget.product!.sold : 0,
      revenue: _isEditing ? widget.product!.revenue : 0.0,
      imageUrls: _existingImageUrls, // Bloc will append new images
      pickupLocationIds: _selectedPickupLocationIds,
    );

    context.read<ProductBloc>().add(
      SubmitProductForm(
        product: product,
        newImages: _selectedImages,
        keptImageUrls: _existingImageUrls,
        isUpdate: _isEditing,
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < 3) {
      if (_currentStep == 0) {
        if (_nameController.text.isEmpty || _skuController.text.isEmpty) {
          SnackbarHelper.showError(context, 'Please fill in required fields.');
          return;
        }
      }
      if (_currentStep == 1) {
        if (_priceController.text.isEmpty || _stockController.text.isEmpty) {
          SnackbarHelper.showError(context, 'Please fill in stock and price.');
          return;
        }
      }
      if (_currentStep == 2) {
        // Validate pickup locations are selected
        bool hasError = false;
        if (_allAvailablePickupLocations.isEmpty) {
          hasError = true;
        }
        if (_allAvailablePickupLocations.isNotEmpty &&
            _selectedPickupLocationIds.isEmpty) {
          hasError = true;
        }
        if (hasError) {
          setState(() => _showMediaErrors = true);
          SnackbarHelper.showError(
            context,
            _allAvailablePickupLocations.isEmpty
                ? 'Please add at least one pickup location first.'
                : 'Please select at least one pickup location.',
          );
          return;
        }
      }

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _submitProduct();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductBloc, ProductState>(
      listenWhen: (previous, current) {
        // Only listen if we are submitting or if we get an error/success related to submission
        // Since ProductBloc is shared, we should be careful.
        // ProductSubmitting is distinct.
        // ProductOperationSuccess is distinct.
        // ProductError is distinct.
        return current is ProductSubmitting ||
            current is ProductOperationSuccess ||
            current is ProductError;
      },
      listener: (context, state) {
        if (state is ProductSubmitting) {
          setState(() => _isSubmitting = true);
        } else if (state is ProductOperationSuccess) {
          // Check if this success is relevant to us? (Add/Update message)
          // If we triggered it, _isSubmitting is true.
          if (_isSubmitting) {
            setState(() => _isSubmitting = false);
            SnackbarHelper.showSuccess(context, state.message);
            context.pop();
          }
        } else if (state is ProductError) {
          if (_isSubmitting) {
            setState(() => _isSubmitting = false);
            SnackbarHelper.showError(context, state.message);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: _previousStep,
          ),
          title: Text(
            _isEditing ? 'Edit Product' : 'Add Product',
            style: AppTextStyles.h3,
          ),
          centerTitle: false,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingL,
              ),
              child: StepIndicator(
                currentStep: _currentStep,
                totalSteps: 4,
                stepLabels: _stepLabels,
                activeColor: AppColors.primary,
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildBasicInfoStep(),
                    _buildPricingStep(),
                    _buildMediaStep(),
                    _buildReviewStep(),
                  ],
                ),
              ),
            ),
            _buildBottomAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '* Fields are required',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.error,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          FarmTextField(
            controller: _nameController,
            label: 'Product Name *',
            hint: 'e.g., Fresh Tomatoes',
            validator: Validators.validateRequired,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          FarmTextField(
            controller: _skuController,
            label: 'SKU *',
            hint: 'e.g., TOM-001',
            validator: Validators.validateRequired,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          FarmDropdown<ProductCategory>(
            label: 'Category',
            value: _selectedCategory,
            items: ProductCategory.values.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Row(
                  children: [
                    Text(category.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: AppDimensions.spacingM),
                    Text(category.displayName, style: AppTextStyles.body1),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCategory = value);
              }
            },
          ),
          const SizedBox(height: AppDimensions.spacingL),
          FarmTextField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Tell customers more about your product...',
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FarmTextField(
            controller: _priceController,
            label: 'Price (₱) *',
            hint: '0.00',
            keyboardType: TextInputType.number,
            validator: Validators.validatePrice,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          FarmTextField(
            controller: _stockController,
            label: 'Current Stock *',
            hint: '0',
            keyboardType: TextInputType.number,
            validator: Validators.validateStock,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          FarmTextField(
            controller: _minStockController,
            label: 'Minimum Stock Level',
            hint: '10',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return null;
              } // Optional? Or default 10?
              // Assuming it accepts an empty value or valid stock
              return Validators.validateStock(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMediaStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Product Images'),
          const SizedBox(height: AppDimensions.spacingS),
          _buildImagePicker(),
          const SizedBox(height: AppDimensions.spacingXL),
          _buildPickupLocationSection(),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: _buildProductReviewSection(),
    );
  }

  Widget _buildProductReviewSection() {
    final totalImages = _existingImageUrls.length + _selectedImages.length;
    final selectedLocations = _allAvailablePickupLocations
        .where((loc) => _selectedPickupLocationIds.contains(loc.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.checklist_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Text('Review Product Details', style: AppTextStyles.h4),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingL),
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              // Basic Info Section
              _buildReviewRow(
                icon: Icons.inventory_2_outlined,
                label: 'Product Name',
                value: _nameController.text.isEmpty
                    ? 'Not set'
                    : _nameController.text,
              ),
              const Divider(height: 24),
              _buildReviewRow(
                icon: Icons.qr_code_outlined,
                label: 'SKU',
                value: _skuController.text.isEmpty
                    ? 'Not set'
                    : _skuController.text,
              ),
              const Divider(height: 24),
              _buildReviewRow(
                icon: Icons.category_outlined,
                label: 'Category',
                value: _selectedCategory.displayName,
              ),
              if (_descriptionController.text.isNotEmpty) ...[
                const Divider(height: 24),
                _buildReviewRow(
                  icon: Icons.description_outlined,
                  label: 'Description',
                  value: _descriptionController.text,
                  isMultiLine: true,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingL),
        // Pricing Section
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildReviewRow(
                icon: Icons.attach_money,
                label: 'Price',
                value: _priceController.text.isEmpty
                    ? 'Not set'
                    : '₱${_priceController.text}',
                valueColor: AppColors.primary,
              ),
              const Divider(height: 24),
              _buildReviewRow(
                icon: Icons.inventory_outlined,
                label: 'Current Stock',
                value: _stockController.text.isEmpty
                    ? 'Not set'
                    : '${_stockController.text} units',
              ),
              const Divider(height: 24),
              _buildReviewRow(
                icon: Icons.warning_amber_outlined,
                label: 'Min Stock Alert',
                value: _minStockController.text.isEmpty
                    ? '10 units (default)'
                    : '${_minStockController.text} units',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingL),
        // Media & Locations Section
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildReviewRow(
                icon: Icons.photo_library_outlined,
                label: 'Images',
                value: totalImages == 0
                    ? 'No images added'
                    : '$totalImages image${totalImages > 1 ? 's' : ''} added',
              ),
              const Divider(height: 24),
              _buildReviewRow(
                icon: Icons.location_on_outlined,
                label: 'Pickup Locations',
                value: selectedLocations.isEmpty
                    ? 'Available at all locations'
                    : selectedLocations.map((l) => l.name).join(', '),
                isMultiLine: selectedLocations.length > 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingL),
        // Info Banner
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Text(
                  _isEditing
                      ? 'Review the details above and tap "Update Product" to save your changes.'
                      : 'Review the details above and tap "Add Product" to publish.',
                  style: AppTextStyles.body2.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMultiLine = false,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: isMultiLine
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: isMultiLine
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: AppTextStyles.body2.copyWith(
                        fontWeight: FontWeight.w500,
                        color: valueColor ?? AppColors.textPrimary,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        value,
                        style: AppTextStyles.body2.copyWith(
                          fontWeight: FontWeight.w500,
                          color: valueColor ?? AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: Colors.white,
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
            if (_currentStep > 0) ...[
              Expanded(
                flex: 1,
                child: FarmButton(
                  label: 'Back',
                  onPressed: _previousStep,
                  style: FarmButtonStyle.outline,
                  isFullWidth: true,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
            ],
            Expanded(
              flex: 2,
              child: FarmButton(
                label: _currentStep == 3
                    ? (_isEditing ? 'Update Product' : 'Add Product')
                    : 'Continue',
                onPressed: _isSubmitting ? null : _nextStep,
                isLoading: _isSubmitting,
                style: FarmButtonStyle.primary,
                isFullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    final totalImages = _existingImageUrls.length + _selectedImages.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (totalImages > 0)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: totalImages,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppDimensions.spacingS),
              itemBuilder: (context, index) {
                final isExisting = index < _existingImageUrls.length;

                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusM,
                        ),
                        image: DecorationImage(
                          image: isExisting
                              ? NetworkImage(_existingImageUrls[index])
                                    as ImageProvider
                              : MemoryImage(
                                  _imagePreviews[index -
                                      _existingImageUrls.length],
                                ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => isExisting
                            ? _removeExistingImage(index)
                            : _removeNewImage(
                                index - _existingImageUrls.length,
                              ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        if (totalImages > 0) const SizedBox(height: AppDimensions.spacingM),
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.paddingL,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color: AppColors.border,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.add_a_photo_outlined,
                  color: AppColors.primary,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  totalImages == 0 ? 'Choose Photo' : 'Add more images',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _buildPickupLocationSection() {
    // Get selected locations with coordinates for map display
    final selectedWithCoords = _allAvailablePickupLocations
        .where(
          (loc) =>
              _selectedPickupLocationIds.contains(loc.id) &&
              loc.coordinates != null,
        )
        .toList();

    // Determine error states
    final bool hasNoLocations = _allAvailablePickupLocations.isEmpty;
    final bool hasNoSelection =
        _allAvailablePickupLocations.isNotEmpty &&
        _selectedPickupLocationIds.isEmpty;
    final bool showError =
        _showMediaErrors && (hasNoLocations || hasNoSelection);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildLabel('Pickup Locations'),
                Text(
                  ' *',
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => _showAddLocationDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add New'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingS),
        if (_allAvailablePickupLocations.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.paddingXL,
              horizontal: AppDimensions.paddingM,
            ),
            decoration: BoxDecoration(
              color: showError ? AppColors.errorLight : AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color: showError ? AppColors.error : AppColors.border,
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    showError ? Icons.error_outline : Icons.map_outlined,
                    size: 48,
                    color: showError
                        ? AppColors.error
                        : AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  Text(
                    'No pickup locations added yet',
                    style: showError
                        ? AppTextStyles.body2.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          )
                        : AppTextStyles.body2Secondary,
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  Text(
                    'Add your first location to continue',
                    style: AppTextStyles.cardCaption.copyWith(
                      color: showError ? AppColors.error : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ..._allAvailablePickupLocations.map((location) {
            final isSelected = _selectedPickupLocationIds.contains(location.id);
            return PickupLocationTile(
              location: location,
              isSelectionMode: true,
              isSelected: isSelected,
              onDelete: () => _deletePickupLocation(location),
              onEdit: () => _showAddLocationDialog(locationToEdit: location),
              onSelectionChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selectedPickupLocationIds.add(location.id);
                  } else {
                    _selectedPickupLocationIds.remove(location.id);
                  }
                  // Clear error when user makes a selection
                  if (_selectedPickupLocationIds.isNotEmpty) {
                    _showMediaErrors = false;
                  }
                });
              },
            );
          }),
        // Show error message when locations exist but none selected
        if (showError && hasNoSelection)
          Padding(
            padding: const EdgeInsets.only(top: AppDimensions.spacingS),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 16,
                ),
                const SizedBox(width: AppDimensions.spacingXS),
                Text(
                  'Please select at least one pickup location',
                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                ),
              ],
            ),
          ),
        // Map preview for selected locations with coordinates
        if (selectedWithCoords.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.spacingL),
          Text('Selected Locations Map', style: AppTextStyles.labelMedium),
          const SizedBox(height: AppDimensions.spacingS),
          MapDisplayWidget(
            markers: selectedWithCoords
                .map(
                  (loc) => MapMarkerData(
                    id: loc.id,
                    location: loc.coordinates!,
                    title: loc.name,
                    subtitle: loc.address,
                  ),
                )
                .toList(),
            height: 180,
            showDirectionsButton: false,
          ),
        ],
      ],
    );
  }

  Future<void> _showAddLocationDialog({PickupLocation? locationToEdit}) async {
    final nameController = TextEditingController(
      text: locationToEdit?.name ?? '',
    );
    final addressController = TextEditingController(
      text: locationToEdit?.address ?? '',
    );
    final notesController = TextEditingController(
      text: locationToEdit?.notes ?? '',
    );
    List<PickupWindow> windows = List.from(
      locationToEdit?.availableWindows ?? [],
    );
    GeoLocation? selectedCoordinates = locationToEdit?.coordinates;

    final result = await showDialog<PickupLocation>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
              ),
              titlePadding: const EdgeInsets.all(AppDimensions.paddingL),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingL,
              ),
              actionsPadding: const EdgeInsets.all(AppDimensions.paddingL),
              title: Row(
                children: [
                  Icon(
                    locationToEdit != null
                        ? Icons.edit_location_alt
                        : Icons.add_location,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  Text(
                    locationToEdit != null
                        ? 'Edit Pickup Location'
                        : 'Add Pickup Location',
                    style: AppTextStyles.h4,
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FarmTextField(
                        controller: nameController,
                        label: 'Location Name',
                        hint: 'e.g., Farm Stand, Downtown Market',
                      ),
                      const SizedBox(height: AppDimensions.spacingL),
                      // Integrated Map Picker with Address Search
                      Text(
                        'Address & Location',
                        style: AppTextStyles.labelLarge,
                      ),
                      const SizedBox(height: AppDimensions.spacingS),
                      Text(
                        'Search for an address or drag the map to set location',
                        style: AppTextStyles.cardCaption,
                      ),
                      const SizedBox(height: AppDimensions.spacingM),
                      MapPickerWidget(
                        initialLocation: selectedCoordinates,
                        initialAddress: addressController.text.isNotEmpty
                            ? addressController.text
                            : null,
                        height: 200,
                        showCoordinates: false,
                        onLocationChanged: (newLocation) {
                          setDialogState(() {
                            selectedCoordinates = newLocation;
                          });
                        },
                        onAddressChanged: (newAddress) {
                          addressController.text = newAddress;
                        },
                      ),
                      if (selectedCoordinates != null &&
                          addressController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppDimensions.spacingS,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 16,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Location set',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppDimensions.spacingL),
                      FarmTextField(
                        controller: notesController,
                        label: 'Pickup Instructions (Optional)',
                        hint: 'e.g., Park behind the main barn',
                        maxLines: 2,
                      ),
                      const SizedBox(height: AppDimensions.spacingXL),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pickup Windows',
                            style: AppTextStyles.labelLarge,
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final newWindows = await _showAddWindowDialog(
                                context,
                                windows,
                              );
                              if (newWindows != null && newWindows.isNotEmpty) {
                                setDialogState(() {
                                  windows.addAll(newWindows);
                                });
                              }
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Time'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingS),
                      if (windows.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppDimensions.paddingL,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 32,
                                  color: AppColors.textSecondary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.spacingS),
                                Text(
                                  'No pickup times added yet',
                                  style: AppTextStyles.body2Secondary,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...windows.asMap().entries.map((entry) {
                          final w = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(
                              bottom: AppDimensions.spacingS,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusM,
                              ),
                            ),
                            child: ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.today,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              title: Text(
                                w.dayName,
                                style: AppTextStyles.labelMedium,
                              ),
                              subtitle: Text(w.formattedTimeRange),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                ),
                                color: AppColors.error,
                                onPressed: () {
                                  setDialogState(() {
                                    windows.removeAt(entry.key);
                                  });
                                },
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: AppDimensions.spacingM),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty &&
                        addressController.text.trim().isNotEmpty) {
                      final updatedLocation = PickupLocation(
                        id:
                            locationToEdit?.id ??
                            DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text.trim(),
                        address: addressController.text.trim(),
                        coordinates: selectedCoordinates,
                        notes: notesController.text.trim(),
                        availableWindows: windows,
                      );
                      Navigator.pop(context, updatedLocation);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusL,
                      ),
                    ),
                  ),
                  child: Text(
                    locationToEdit != null
                        ? 'Update Location'
                        : 'Save Location',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    if (!mounted) return;

    if (result != null) {
      final authState = context.read<AuthBloc>().state;
      final userId = authState.userId;
      if (userId != null) {
        try {
          if (locationToEdit != null) {
            // Update existing location
            await _userRepository.updatePickupLocation(
              userId,
              locationToEdit,
              result,
            );
            if (!mounted) return;
            setState(() {
              final index = _allAvailablePickupLocations.indexWhere(
                (l) => l.id == result.id,
              );
              if (index != -1) {
                _allAvailablePickupLocations[index] = result;
              }
            });
            SnackbarHelper.showSuccess(context, 'Pickup location updated!');
          } else {
            // Add new location
            await _userRepository.addPickupLocation(userId, result);
            if (!mounted) return;
            setState(() {
              _allAvailablePickupLocations.add(result);
              _selectedPickupLocationIds.add(result.id);
            });
            SnackbarHelper.showSuccess(context, 'Pickup location added!');
          }
        } catch (e) {
          if (!mounted) return;
          SnackbarHelper.showError(
            context,
            'Error ${locationToEdit != null ? 'updating' : 'adding'} location: $e',
          );
        }
      }
    }
  }

  Future<void> _deletePickupLocation(PickupLocation location) async {
    final authState = context.read<AuthBloc>().state;
    final userId = authState.userId;
    if (userId == null) return;

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
            ),
            title: Row(
              children: [
                const Icon(Icons.delete_outline, color: AppColors.error),
                const SizedBox(width: AppDimensions.spacingM),
                const Text('Delete Location?'),
              ],
            ),
            content: Text(
              'Are you sure you want to delete "${location.name}"? This will remove it from all products.',
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
        ) ??
        false;

    if (confirmed) {
      try {
        await _userRepository.removePickupLocation(userId, location);

        if (!mounted) return;
        setState(() {
          _allAvailablePickupLocations.removeWhere((l) => l.id == location.id);
          _selectedPickupLocationIds.remove(location.id);
        });

        SnackbarHelper.showSuccess(context, 'Location deleted');
      } catch (e) {
        if (!mounted) return;
        SnackbarHelper.showError(context, 'Error deleting location: $e');
      }
    }
  }

  Future<List<PickupWindow>?> _showAddWindowDialog(
    BuildContext context,
    List<PickupWindow> existingWindows,
  ) async {
    Set<int> selectedDays = {};
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);

    return showDialog<List<PickupWindow>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Check for conflicts
          String? conflictMessage;
          if (selectedDays.isNotEmpty) {
            for (final day in selectedDays) {
              for (final existing in existingWindows) {
                if (existing.dayOfWeek == day) {
                  final existingStart =
                      existing.startHour * 60 + existing.startMinute;
                  final existingEnd =
                      existing.endHour * 60 + existing.endMinute;
                  final newStart = startTime.hour * 60 + startTime.minute;
                  final newEnd = endTime.hour * 60 + endTime.minute;

                  if ((newStart < existingEnd && newEnd > existingStart)) {
                    conflictMessage =
                        'Conflicts with existing ${existing.dayName} slot';
                    break;
                  }
                }
              }
              if (conflictMessage != null) break;
            }
          }

          // Check if end time is after start time
          final startMinutes = startTime.hour * 60 + startTime.minute;
          final endMinutes = endTime.hour * 60 + endTime.minute;
          if (endMinutes <= startMinutes) {
            conflictMessage = 'End time must be after start time';
          }

          final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
            ),
            title: Text('Add Time Slot', style: AppTextStyles.h4),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Days', style: AppTextStyles.labelSmall),
                const SizedBox(height: AppDimensions.spacingS),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(7, (index) {
                    final day = index + 1;
                    final isSelected = selectedDays.contains(day);
                    return ChoiceChip(
                      label: Text(
                        dayNames[index],
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setDialogState(() {
                          if (selected) {
                            selectedDays.add(day);
                          } else {
                            selectedDays.remove(day);
                          }
                        });
                      },
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.background,
                      side: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : AppColors.border,
                      ),
                      showCheckmark: false,
                    );
                  }),
                ),
                const SizedBox(height: AppDimensions.spacingL),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('From', style: AppTextStyles.labelSmall),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () async {
                              final t = await FarmTimePicker.show(
                                context,
                                initialTime: startTime,
                              );
                              if (t != null) {
                                setDialogState(() => startTime = t);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusM,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    startTime.format(context),
                                    style: AppTextStyles.body2,
                                  ),
                                  const Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('To', style: AppTextStyles.labelSmall),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () async {
                              final t = await FarmTimePicker.show(
                                context,
                                initialTime: endTime,
                              );
                              if (t != null) {
                                setDialogState(() => endTime = t);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusM,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    endTime.format(context),
                                    style: AppTextStyles.body2,
                                  ),
                                  const Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (conflictMessage != null) ...[
                  const SizedBox(height: AppDimensions.spacingM),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingS),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusS,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            conflictMessage,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedDays.isEmpty || conflictMessage != null
                    ? null
                    : () {
                        final newWindows = selectedDays.map((day) {
                          return PickupWindow(
                            dayOfWeek: day,
                            startHour: startTime.hour,
                            startMinute: startTime.minute,
                            endHour: endTime.hour,
                            endMinute: endTime.minute,
                          );
                        }).toList();
                        Navigator.pop(context, newWindows);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.textTertiary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                ),
                child: const Text('Add Slots'),
              ),
            ],
          );
        },
      ),
    );
  }
}
