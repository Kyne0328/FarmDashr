import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:farmdashr/core/services/google_auth_service.dart';
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

      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthReauthRequired) {
            _handleReauthRequired();
          } else if (state is AuthError) {
            if (mounted) {
              setState(() => _isSaving = false);
              // If error is not re-auth related (which is handled above), show it.
              // Note: AuthBloc emits AuthError for general failures.
              // We can check if the error specifically mentions "requires-recent-login"
              // just in case, but the Bloc should have emitted AuthReauthRequired.
              // Here we just display whatever error came through.
              if (!state.errorMessage!.contains('requires recent login')) {
                SnackbarHelper.showError(
                  context,
                  state.errorMessage ?? 'An error occurred',
                );
              }
            }
          }
        },
        child: Stack(
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
                    _buildSecurityButton(),
                    const SizedBox(height: AppDimensions.spacingM),
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

  Future<void> _handleReauthRequired() async {
    // 1. Determine provider
    final user = FirebaseAuth.instance.currentUser;
    final isGoogle =
        user?.providerData.any((p) => p.providerId == 'google.com') ?? false;
    final hasPassword =
        user?.providerData.any((p) => p.providerId == 'password') ?? false;

    if (!mounted) return;

    // 2. Show info dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Security Verification Required'),
        content: const Text(
          'For your security, you must verify your identity shortly before deleting your account.\n\nPlease sign in again to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              setState(() => _isSaving = false); // Stop loading spinner
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _performReauth(isGoogle, hasPassword);
            },
            child: const Text('Verify & Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _performReauth(bool isGoogle, bool hasPassword) async {
    try {
      if (isGoogle) {
        // Trigger Google Re-auth
        setState(() => _isSaving = true); // Show loading
        await context.read<GoogleAuthService>().reauthenticate();

        // If successful, retry deletion immediately
        if (mounted) {
          context.read<AuthBloc>().add(const AuthDeleteAccountRequested());
        }
      } else if (hasPassword) {
        // Show password dialog again
        // Note: The previous password might be stale/incorrect if we reached here,
        // or the session merely timed out. Logic is same as initial confirmation.
        setState(() => _isSaving = false); // Hide loading to show dialog
        final password = await showDialog<String>(
          context: context,
          builder: (context) => const _DeleteAccountPasswordDialog(),
        );

        if (password != null && mounted) {
          setState(() => _isSaving = true);
          context.read<AuthBloc>().add(
            AuthDeleteAccountRequested(password: password),
          );
        }
      } else {
        // Fallback or other providers
        if (mounted) {
          SnackbarHelper.showError(
            context,
            'Please log out and log in again to delete your account.',
          );
          setState(() => _isSaving = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        SnackbarHelper.showError(
          context,
          'Verification failed: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    // Check if user has a password provider
    final hasPassword =
        user?.providerData.any(
          (userInfo) => userInfo.providerId == 'password',
        ) ??
        false;

    if (hasPassword) {
      // Show password confirmation
      final password = await showDialog<String>(
        context: context,
        builder: (context) => const _DeleteAccountPasswordDialog(),
      );

      if (password != null && mounted) {
        context.read<AuthBloc>().add(
          AuthDeleteAccountRequested(password: password),
        );
        setState(() => _isSaving = true);
      }
    } else {
      // Show "Type DELETE" confirmation for Google/Social users
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => const _DeleteAccountConfirmationDialog(),
      );

      if (confirmed == true && mounted) {
        // Send request without password
        context.read<AuthBloc>().add(const AuthDeleteAccountRequested());
        setState(() => _isSaving = true);
      }
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
          height: 56,
        ),
      ),
    );
  }

  Widget _buildSecurityButton() {
    final user = FirebaseAuth.instance.currentUser;
    final hasPassword =
        user?.providerData.any((p) => p.providerId == 'password') ?? false;

    if (hasPassword) {
      return Center(
        child: TextButton.icon(
          onPressed: () => context.push('/change-password'),
          icon: const Icon(Icons.lock_outline, size: 20),
          label: const Text('Change Password'),
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
      );
    } else {
      return Center(
        child: TextButton.icon(
          onPressed: () => context.push('/set-password'),
          icon: const Icon(Icons.password, size: 20),
          label: const Text('Set Password'),
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
      );
    }
  }
}

class _DeleteAccountPasswordDialog extends StatefulWidget {
  const _DeleteAccountPasswordDialog();

  @override
  State<_DeleteAccountPasswordDialog> createState() =>
      _DeleteAccountPasswordDialogState();
}

class _DeleteAccountPasswordDialogState
    extends State<_DeleteAccountPasswordDialog> {
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

class _DeleteAccountConfirmationDialog extends StatefulWidget {
  const _DeleteAccountConfirmationDialog();

  @override
  State<_DeleteAccountConfirmationDialog> createState() =>
      _DeleteAccountConfirmationDialogState();
}

class _DeleteAccountConfirmationDialogState
    extends State<_DeleteAccountConfirmationDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _canDelete = _controller.text == 'DELETE';
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
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
              'This action cannot be undone. All your data will be lost permanently.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body2Secondary,
            ),
            const SizedBox(height: AppDimensions.spacingXL),
            Text(
              'Type "DELETE" to confirm',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            TextField(
              controller: _controller,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'DELETE',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.paddingM,
                  horizontal: AppDimensions.paddingM,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXL),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => context.pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canDelete ? () => context.pop(true) : null,
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
    );
  }
}
