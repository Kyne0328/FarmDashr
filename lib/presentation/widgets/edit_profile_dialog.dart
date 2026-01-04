import 'package:flutter/material.dart';
import 'package:farmdashr/core/utils/snackbar_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:farmdashr/core/services/cloudinary_service.dart';
import 'package:farmdashr/blocs/auth/auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:farmdashr/presentation/widgets/common/farm_text_field.dart';
import 'package:farmdashr/presentation/widgets/common/farm_button.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditProfileDialog extends StatefulWidget {
  final UserProfile userProfile;

  const EditProfileDialog({super.key, required this.userProfile});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  XFile? _imageFile;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userProfile.name);
    _emailController = TextEditingController(text: widget.userProfile.email);
    // Initialize phone with +63 prefix if empty
    final phone = widget.userProfile.phone ?? '';
    _phoneController = TextEditingController(
      text: phone.isEmpty ? '+63 ' : phone,
    );
    _addressController = TextEditingController(
      text: widget.userProfile.address ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageFile = image;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUploading = true);

      String? imageUrl = widget.userProfile.profilePictureUrl;

      if (_imageFile != null) {
        final uploadedUrl = await _cloudinaryService.uploadImage(_imageFile!);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        } else {
          if (mounted) {
            SnackbarHelper.showError(
              context,
              'Failed to upload image. Please try again.',
            );
            setState(() => _isUploading = false);
            return;
          }
        }
      }

      if (mounted) {
        final newName = _nameController.text.trim();
        final updatedProfile = widget.userProfile.copyWith(
          name: newName,
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          profilePictureUrl: imageUrl,
        );

        // Sync with AuthBloc so Home Page updates immediately
        if (newName != widget.userProfile.name) {
          context.read<AuthBloc>().add(AuthUpdateDisplayNameRequested(newName));
        }

        Navigator.of(context).pop(updatedProfile);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
      ),
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingXXL),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const Divider(
                        height: AppDimensions.spacingXL,
                        color: AppColors.border,
                      ),
                      _buildPhotoSection(),
                      const SizedBox(height: AppDimensions.spacingXL),
                      FarmTextField(
                        label: 'Full Name *',
                        hint: 'Your full name',
                        controller: _nameController,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppDimensions.spacingL),
                      FarmTextField(
                        label: 'Email Address *',
                        hint: 'you@example.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (!value.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppDimensions.spacingL),
                      FarmTextField(
                        label: 'Phone Number *',
                        hint: '+63 912 345 6789',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppDimensions.spacingL),
                      FarmTextField(
                        label: 'Address *',
                        hint: '123 Farm Road, City, State',
                        controller: _addressController,
                        maxLines: 3,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppDimensions.spacingXL),
                      _buildActionButtons(context),
                    ],
                  ),
                ),
              ),
            ),
            if (_isUploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Edit Profile',
          style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
        ),
        IconButton(
          onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Photo',
          style: AppTextStyles.body2Secondary.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Row(
          children: [
            CircleAvatar(
              radius: AppDimensions.avatarS,
              backgroundColor: AppColors.primaryLight,
              backgroundImage: _imageBytes != null
                  ? MemoryImage(_imageBytes!)
                  : (widget.userProfile.profilePictureUrl != null
                        ? CachedNetworkImageProvider(
                                widget.userProfile.profilePictureUrl!,
                              )
                              as ImageProvider
                        : null),
              child:
                  (_imageBytes == null &&
                      widget.userProfile.profilePictureUrl == null)
                  ? const Icon(
                      Icons.person_outline,
                      size: AppDimensions.iconXL,
                      color: AppColors.primary,
                    )
                  : null,
            ),
            const SizedBox(width: AppDimensions.spacingL),
            FarmButton(
              label: 'Change Photo',
              onPressed: _isUploading ? null : _pickImage,
              style: FarmButtonStyle
                  .outline, // Using outline or similar for secondary action
              height: 36,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FarmButton(
            label: 'Cancel',
            onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
            style: FarmButtonStyle.ghost,
            isFullWidth: true,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: FarmButton(
            label: 'Save Changes',
            onPressed: _isUploading ? null : _handleSave,
            isLoading: _isUploading,
            style: FarmButtonStyle.primary,
            backgroundColor: AppColors.primary,
            isFullWidth: true,
          ),
        ),
      ],
    );
  }
}
