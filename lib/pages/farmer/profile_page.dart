import 'package:flutter/material.dart';
import 'package:farmdashr/data/repositories/repositories.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/utils/snackbar_helper.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/services/haptic_service.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:farmdashr/blocs/auth/auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:farmdashr/presentation/widgets/common/farm_button.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserRepository _userRepo = FirestoreUserRepository();
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _userRepo.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToEditProfile() async {
    if (_userProfile == null) return;

    final updatedProfile = await context.push<UserProfile>(
      '/edit-profile',
      extra: _userProfile!,
    );

    if (updatedProfile != null && mounted) {
      setState(() => _isLoading = true);
      try {
        await _userRepo.update(updatedProfile);
        if (mounted) {
          setState(() {
            _userProfile = updatedProfile;
            _isLoading = false;
          });
          if (context.mounted) {
            SnackbarHelper.showSuccess(context, 'Profile updated successfully');
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          if (context.mounted) {
            SnackbarHelper.showError(
              context,
              'Failed to update profile: ${e.toString()}',
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(),
            const SizedBox(height: AppDimensions.spacingXL),

            // Menu Items
            _MenuOption(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              onTap: _navigateToEditProfile,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            _MenuOption(
              icon: Icons.business_outlined,
              title: 'Business Information',
              subtitle: 'Manage your farm details',
              onTap: () => context.push('/business-info'),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            _MenuOption(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Order updates & alerts',
              onTap: () => context.push('/notification-settings'),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            _MenuOption(
              icon: Icons.swap_horiz,
              title: 'Switch to User Account',
              subtitle: 'Browse and buy products',
              onTap: () {
                if (context.mounted) {
                  context.go('/customer-home');
                }
              },
            ),
            const SizedBox(height: AppDimensions.spacingM),
            _MenuOption(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () => context.push('/help-support'),
            ),
            const SizedBox(height: AppDimensions.spacingXXL),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FarmButton(
        label: 'Log Out',
        onPressed: () {
          HapticService.selection();
          context.read<AuthBloc>().add(const AuthSignOutRequested());
          if (context.mounted) {
            context.go('/');
          }
        },
        style: FarmButtonStyle.danger,
        isFullWidth: true,
        height: 56,
      ),
    );
  }

  Widget _buildProfileHeader() {
    final authState = context.watch<AuthBloc>().state;
    final userName = _isLoading
        ? 'Loading...'
        : (_userProfile?.name ?? authState.displayName ?? 'Farmer');
    final userEmail = _userProfile?.email ?? authState.email ?? '';

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingXL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 35,
            backgroundColor: AppColors.farmerPrimaryLight,
            backgroundImage: _userProfile?.profilePictureUrl != null
                ? CachedNetworkImageProvider(_userProfile!.profilePictureUrl!)
                : null,
            child: _userProfile?.profilePictureUrl == null
                ? const Icon(
                    Icons.person,
                    size: 40,
                    color: AppColors.farmerPrimary,
                  )
                : null,
          ),
          const SizedBox(width: AppDimensions.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: AppTextStyles.sectionTitle),
                const SizedBox(height: 4),
                Text(userEmail, style: AppTextStyles.body2Secondary),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.farmerPrimaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Farmer Account',
                    style: AppTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.farmerPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple menu option with InkWell feedback
class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuOption({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticService.selection();
        onTap();
      },
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.containerLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.iconDefault, size: 24),
            ),
            const SizedBox(width: AppDimensions.spacingL),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLarge),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppTextStyles.cardCaption),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.iconTertiary),
          ],
        ),
      ),
    );
  }
}
