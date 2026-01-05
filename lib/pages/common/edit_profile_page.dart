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
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/utils/validators.dart';

class EditProfilePage extends StatefulWidget {
  final UserProfile userProfile;

  const EditProfilePage({super.key, required this.userProfile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  XFile? _imageFile;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  bool _isSaving = false;

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
      setState(() => _isSaving = true);

      try {
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
              setState(() => _isSaving = false);
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
            context.read<AuthBloc>().add(
              AuthUpdateDisplayNameRequested(newName),
            );
          }

          // Return the updated profile object so the parent page can refresh its state
          context.pop(updatedProfile);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          SnackbarHelper.showError(context, 'Error saving profile: $e');
        }
      }
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
        title: Text('Edit Profile', style: AppTextStyles.h3),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    validator: Validators.validatePhilippinesPhone,
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
                  const SizedBox(height: AppDimensions.spacingXXL),
                  Center(
                    child: TextButton(
                      onPressed: _isSaving ? null : _confirmDeleteAccount,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: const Text('Delete Account'),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingL),
                ],
              ),
            ),
          ),
          if (_isSaving)
            Positioned.fill(
              child: Container(
                color: Colors.white.withValues(alpha: 0.7),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomAction(),
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
              radius: 40,
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
                      size: 40,
                      color: AppColors.primary,
                    )
                  : null,
            ),
            const SizedBox(width: AppDimensions.spacingL),
            FarmButton(
              label: 'Choose Photo',
              onPressed: _isSaving ? null : _pickImage,
              style: FarmButtonStyle.outline,
              height: 40,
              width: 130,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final password = await showDialog<String>(
      context: context,
      builder: (context) => const _DeleteAccountDialog(),
    );

    if (password != null && mounted) {
      context.read<AuthBloc>().add(
        AuthDeleteAccountRequested(password: password),
      );
      // Show loading while bloc handles it
      setState(() => _isSaving = true);
    }
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
        child: FarmButton(
          label: 'Save Changes',
          onPressed: _isSaving ? null : _handleSave,
          isLoading: _isSaving,
          style: FarmButtonStyle.primary,
          isFullWidth: true,
          height: 56,
        ),
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: AppColors.error,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingL),
              Text('Delete Account?', style: AppTextStyles.h3),
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                'This action cannot be undone. Please enter your password to confirm.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body2Secondary,
              ),
              const SizedBox(height: AppDimensions.spacingXL),
              FarmTextField(
                controller: _passwordController,
                hint: 'Enter your password',
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.textTertiary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.spacingXL),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => context.pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          context.pop(_passwordController.text);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.error.withValues(
                          alpha: 0.3,
                        ),
                        disabledForegroundColor: Colors.white.withValues(
                          alpha: 0.7,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusM,
                          ),
                        ),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
