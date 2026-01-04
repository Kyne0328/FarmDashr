import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/data/models/product/product.dart';
import 'package:farmdashr/data/repositories/product/product_repository.dart';
import 'package:farmdashr/blocs/product/product.dart';
import 'package:farmdashr/blocs/auth/auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:farmdashr/core/services/cloudinary_service.dart';
import 'package:farmdashr/data/models/auth/pickup_location.dart';
import 'package:farmdashr/data/repositories/auth/user_repository.dart';
// import 'package:farmdashr/data/models/auth/user_profile.dart'; // Removed unused import

import 'package:farmdashr/presentation/widgets/common/step_indicator.dart';
import 'package:farmdashr/core/utils/snackbar_helper.dart';

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
  final UserRepository _userRepository = UserRepository();

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final List<Uint8List> _imagePreviews = [];
  final List<String> _existingImageUrls = [];
  final CloudinaryService _cloudinaryService = CloudinaryService();

  bool get _isEditing => widget.product != null;

  final PageController _pageController = PageController();
  int _currentStep = 0;
  final List<String> _stepLabels = ['Basic Info', 'Pricing', 'Media'];

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
      if (profile != null && profile.businessInfo != null) {
        if (!mounted) return;
        setState(() {
          _allAvailablePickupLocations = profile.businessInfo!.pickupLocations;
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

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthBloc>().state;
    final userId = authState.userId;

    if (userId == null) {
      SnackbarHelper.showError(context, 'Error: User not authenticated');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final productRepo = ProductRepository();
      final sku = _skuController.text.trim();
      final isUnique = await productRepo.isSkuUnique(
        sku,
        userId,
        excludeProductId: _isEditing ? widget.product!.id : null,
      );

      if (!isUnique) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        SnackbarHelper.showError(
          context,
          'SKU "$sku" already exists. Please use a unique SKU.',
        );
        return;
      }

      final List<String> newImageUrls = await _cloudinaryService.uploadImages(
        _selectedImages,
      );

      final List<String> finalImageUrls = [
        ..._existingImageUrls,
        ...newImageUrls,
      ];

      final product = Product(
        id: _isEditing ? widget.product!.id : '',
        farmerId: userId,
        farmerName: authState.displayName ?? 'Farmer',
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
        imageUrls: finalImageUrls,
        pickupLocationIds: _selectedPickupLocationIds,
      );

      if (!mounted) return;

      if (_isEditing) {
        context.read<ProductBloc>().add(UpdateProduct(product));
      } else {
        context.read<ProductBloc>().add(AddProduct(product));
      }

      SnackbarHelper.showSuccess(
        context,
        _isEditing
            ? 'Product updated successfully!'
            : 'Product added successfully!',
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      SnackbarHelper.showError(context, 'Error saving product: $e');
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
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
    return Scaffold(
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
              totalSteps: 3,
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
                ],
              ),
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Product Name *'),
          const SizedBox(height: AppDimensions.spacingS),
          _buildTextField(
            controller: _nameController,
            hint: 'e.g., Fresh Tomatoes',
            validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          _buildLabel('SKU *'),
          const SizedBox(height: AppDimensions.spacingS),
          _buildTextField(
            controller: _skuController,
            hint: 'e.g., TOM-001',
            validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          _buildLabel('Category'),
          const SizedBox(height: AppDimensions.spacingS),
          _buildDropdown(),
          const SizedBox(height: AppDimensions.spacingL),
          _buildLabel('Description'),
          const SizedBox(height: AppDimensions.spacingS),
          _buildTextField(
            controller: _descriptionController,
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
          _buildLabel('Price (₱) *'),
          const SizedBox(height: AppDimensions.spacingS),
          _buildTextField(
            controller: _priceController,
            hint: '0.00',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (double.tryParse(value) == null) return 'Invalid';
              return null;
            },
          ),
          const SizedBox(height: AppDimensions.spacingL),
          _buildLabel('Current Stock *'),
          const SizedBox(height: AppDimensions.spacingS),
          _buildTextField(
            controller: _stockController,
            hint: '0',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (int.tryParse(value) == null) return 'Invalid';
              return null;
            },
          ),
          const SizedBox(height: AppDimensions.spacingL),
          _buildLabel('Minimum Stock Level'),
          const SizedBox(height: AppDimensions.spacingS),
          _buildTextField(
            controller: _minStockController,
            hint: '10',
            keyboardType: TextInputType.number,
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
          const SizedBox(height: AppDimensions.spacingXL),
          _buildProductReviewSection(),
        ],
      ),
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
              OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(100, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                ),
                child: const Text('Back'),
              ),
              const SizedBox(width: AppDimensions.spacingM),
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _currentStep == 2
                            ? (_isEditing ? 'Update Product' : 'Add Product')
                            : 'Continue',
                        style: AppTextStyles.button,
                      ),
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
                  totalImages == 0 ? 'Tap to add images' : 'Add more images',
                  style: AppTextStyles.body2.copyWith(color: AppColors.primary),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body2.copyWith(color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingL,
          vertical: AppDimensions.paddingM,
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ProductCategory>(
          value: _selectedCategory,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: ProductCategory.values.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category.displayName, style: AppTextStyles.body2),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedCategory = value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildPickupLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('Pickup Locations'),
            TextButton.icon(
              onPressed: _showAddLocationDialog,
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
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: Text(
                    'No pickup locations added yet. Add your first location to continue.',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: AppDimensions.spacingS,
            runSpacing: AppDimensions.spacingS,
            children: _allAvailablePickupLocations.map((location) {
              final isSelected = _selectedPickupLocationIds.contains(
                location.id,
              );
              return FilterChip(
                label: Text(location.name),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedPickupLocationIds.add(location.id);
                    } else {
                      _selectedPickupLocationIds.remove(location.id);
                    }
                  });
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primary,
                labelStyle: AppTextStyles.body2.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Future<void> _showAddLocationDialog() async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Dialog state
    final selectedDays = <int>{}; // 1 = Mon, 7 = Sun
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);

    final result = await showDialog<PickupLocation>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Pickup Location', style: AppTextStyles.h3),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Location Name',
                          hintText: 'e.g., Farm Stand #1',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppDimensions.spacingM),
                      TextFormField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          hintText: 'Full physical address',
                        ),
                        maxLines: 2,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppDimensions.spacingM),
                      TextFormField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          hintText: 'Special instructions',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: AppDimensions.spacingL),
                      const Text(
                        'Select Pickup Days',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppDimensions.spacingS),
                      Wrap(
                        spacing: 4,
                        children: List.generate(7, (index) {
                          final day = index + 1;
                          final dayName = _getDayLetter(day);
                          final isSelected = selectedDays.contains(day);
                          return ChoiceChip(
                            label: Text(dayName),
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
                          );
                        }),
                      ),
                      const SizedBox(height: AppDimensions.spacingM),
                      const Text(
                        'Time Window',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppDimensions.spacingS),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: startTime,
                                );
                                if (picked != null) {
                                  setDialogState(() => startTime = picked);
                                }
                              },
                              child: Text(startTime.format(context)),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('to'),
                          ),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: endTime,
                                );
                                if (picked != null) {
                                  setDialogState(() => endTime = picked);
                                }
                              },
                              child: Text(endTime.format(context)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      if (selectedDays.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select at least one day'),
                          ),
                        );
                        return;
                      }

                      final windows = selectedDays.map((day) {
                        return PickupWindow(
                          dayOfWeek: day,
                          startHour: startTime.hour,
                          startMinute: startTime.minute,
                          endHour: endTime.hour,
                          endMinute: endTime.minute,
                        );
                      }).toList();

                      final newLocation = PickupLocation(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text.trim(),
                        address: addressController.text.trim(),
                        notes: notesController.text.trim(),
                        availableWindows: windows,
                      );
                      Navigator.pop(context, newLocation);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add'),
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
          // Save to user profile
          await _userRepository.addPickupLocation(userId, result);

          if (!mounted) return;
          setState(() {
            _allAvailablePickupLocations.add(result);
            _selectedPickupLocationIds.add(result.id);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pickup location added!')),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding location: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  String _getDayLetter(int day) {
    switch (day) {
      case 1:
        return 'M';
      case 2:
        return 'T';
      case 3:
        return 'W';
      case 4:
        return 'T';
      case 5:
        return 'F';
      case 6:
        return 'S';
      case 7:
        return 'S';
      default:
        return '';
    }
  }
}
