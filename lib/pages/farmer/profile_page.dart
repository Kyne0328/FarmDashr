import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:farmdashr/data/repositories/auth/user_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:farmdashr/blocs/auth/auth.dart';
import 'package:farmdashr/presentation/widgets/edit_profile_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserRepository _userRepo = UserRepository();
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

  Future<void> _showEditProfileDialog() async {
    if (_userProfile == null) return;

    final updatedProfile = await showDialog<UserProfile>(
      context: context,
      builder: (context) => EditProfileDialog(userProfile: _userProfile!),
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update profile: ${e.toString()}'),
              ),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildStatsRow(),
            const SizedBox(height: 24),
            _buildMenuOption(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              onTap: _showEditProfileDialog,
            ),
            const SizedBox(height: 12),
            _buildMenuOption(
              icon: Icons.business_outlined,
              title: 'Business Information',
              subtitle: 'Manage your farm details',
              onTap: () => context.push('/business-info'),
            ),
            const SizedBox(height: 12),
            _buildMenuOption(
              icon: Icons.swap_horiz,
              title: 'Switch to User Account',
              subtitle: 'Browse and buy products',
              onTap: () {
                if (context.mounted) {
                  context.go('/customer-home');
                }
              },
            ),
            const SizedBox(height: 12),
            _buildMenuOption(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {},
            ),
            const SizedBox(height: 32),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          context.read<AuthBloc>().add(const AuthSignOutRequested());
          if (context.mounted) {
            context.go('/');
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          'Log Out',
          style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final userName = _isLoading
        ? 'Loading...'
        : (_userProfile?.name ??
              FirebaseAuth.instance.currentUser?.displayName ??
              'Farmer');
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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
          const SizedBox(width: 16),
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

  Widget _buildStatsRow() {
    final stats = _userProfile?.stats;
    final productsSold = stats?.productsSold.toString() ?? '0';
    final totalRevenue = stats?.totalRevenue.toStringAsFixed(0) ?? '0';
    final totalOrders = stats?.totalOrders.toString() ?? '0';
    final totalCustomers = stats?.totalCustomers.toString() ?? '0';

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard(productsSold, 'Products Sold')),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('\$$totalRevenue', 'Revenue')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard(totalOrders, 'Total Orders')),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(totalCustomers, 'Customers')),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.priceLarge),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.cardCaption),
        ],
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
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
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLarge),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.cardCaption),
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
