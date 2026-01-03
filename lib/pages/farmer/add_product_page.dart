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

  final List<String> _selectedPickupLocationIds = []; // Added
  List<PickupLocation> _allAvailablePickupLocations = []; // Added
  final UserRepository _userRepository = UserRepository(); // Added

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final List<Uint8List> _imagePreviews = [];
  final List<String> _existingImageUrls = [];
  final CloudinaryService _cloudinaryService = CloudinaryService();

  bool get _isEditing => widget.product != null;

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
      _selectedPickupLocationIds.addAll(p.pickupLocationIds); // Added
    }
    _loadUserPickupLocations(); // Added
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: User not authenticated'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 0. Validate SKU uniqueness
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'SKU "$sku" already exists. Please use a unique SKU.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // 1. Upload new images to Cloudinary
      final List<String> newImageUrls = await _cloudinaryService.uploadImages(
        _selectedImages,
      );

      // Combine existing (that weren't removed) and new URLs
      final List<String> finalImageUrls = [
        ..._existingImageUrls,
        ...newImageUrls,
      ];

      // 2. Create/Update product
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
        pickupLocationIds: _selectedPickupLocationIds, // Added
      );

      if (!mounted) return;

      if (_isEditing) {
        context.read<ProductBloc>().add(UpdateProduct(product));
      } else {
        context.read<ProductBloc>().add(AddProduct(product));
      }

      // Show success and go back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Product updated successfully!'
                : 'Product added successfully!',
          ),
          backgroundColor: AppColors.primary,
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving product: $e'),
          backgroundColor: AppColors.error,
        ),
      );
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
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEditing ? 'Edit Product' : 'Add Product',
          style: AppTextStyles.h3,
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker Section
              _buildLabel('Product Images'),
              const SizedBox(height: AppDimensions.spacingS),
              _buildImagePicker(),
              const SizedBox(height: AppDimensions.spacingL),

              // Product Name
              _buildLabel('Product Name'),
              const SizedBox(height: AppDimensions.spacingS),
              _buildTextField(
                controller: _nameController,
                hint: 'e.g., Fresh Tomatoes',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.spacingL),

              // SKU
              _buildLabel('SKU'),
              const SizedBox(height: AppDimensions.spacingS),
              _buildTextField(
                controller: _skuController,
                hint: 'e.g., TOM-001',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a SKU';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.spacingL),

              // Description
              _buildLabel('Description'),
              const SizedBox(height: AppDimensions.spacingS),
              _buildTextField(
                controller: _descriptionController,
                hint: 'Tell customers more about your product...',
                maxLines: 4,
                validator: (value) {
                  // Description is optional but could be validated if needed
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.spacingL),

              // Category
              _buildLabel('Category'),
              const SizedBox(height: AppDimensions.spacingS),
              _buildDropdown(),
              const SizedBox(height: AppDimensions.spacingL),

              // Price and Stock Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Price (₱)'),
                        const SizedBox(height: AppDimensions.spacingS),
                        _buildTextField(
                          controller: _priceController,
                          hint: '0.00',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter price';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Current Stock'),
                        const SizedBox(height: AppDimensions.spacingS),
                        _buildTextField(
                          controller: _stockController,
                          hint: '0',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter stock';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingL),

              // Min Stock
              _buildLabel('Minimum Stock Level'),
              const SizedBox(height: AppDimensions.spacingS),
              _buildTextField(
                controller: _minStockController,
                hint: '10',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (int.tryParse(value) == null) {
                      return 'Invalid number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.spacingL),

              // Pickup Locations Section
              _buildPickupLocationSection(),
              const SizedBox(height: AppDimensions.spacingXL),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusM,
                      ),
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
                          _isEditing ? 'Update Product' : 'Add Product',
                          style: AppTextStyles.button,
                        ),
                ),
              ),
            ],
          ),
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
