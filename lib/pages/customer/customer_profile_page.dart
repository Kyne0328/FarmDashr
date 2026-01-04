import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/utils/snackbar_helper.dart';
import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:farmdashr/data/repositories/auth/user_repository.dart';
import 'package:farmdashr/presentation/widgets/edit_profile_dialog.dart';
import 'package:farmdashr/blocs/order/order.dart';
import 'package:farmdashr/blocs/auth/auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  final UserRepository _userRepo = UserRepository();
  UserProfile? _userProfile;
  bool _isLoading = true;
  final bool _isSwitching = false;

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
    return Stack(
      children: [
        SafeArea(
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
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Order updates & alerts',
                  onTap: () => context.push('/notification-settings'),
                ),
                const SizedBox(height: 12),
                _buildMenuOption(
                  icon: Icons.storefront_outlined,
                  title: 'Switch to Farmer',
                  subtitle: 'Manage your farm and products',
                  onTap: (_isLoading || _isSwitching)
                      ? () {
                          if (context.mounted) {
                            SnackbarHelper.showInfo(
                              context,
                              'Please wait, processing...',
                            );
                          }
                        }
                      : () async {
                          // Final check if profile is still null after loading finished
                          if (_userProfile == null) {
                            await _loadUserProfile();
                          }

                          // Guard State use
                          if (!mounted) return;

                          if (_userProfile?.businessInfo == null) {
                            // If they don't have a business profile, go to onboarding
                            if (context.mounted) {
                              context.push('/farmer-onboarding');
                            }
                          } else {
                            // If they are already a farmer (or have a profile), just navigate
                            if (context.mounted) {
                              context.go('/farmer-home-page');
                            }
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
        ),
        if (_isSwitching)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (context.mounted) {
            context.go('/login');
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
              'User');
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
            backgroundColor: AppColors.customerPrimaryLight,
            backgroundImage: _userProfile?.profilePictureUrl != null
                ? CachedNetworkImageProvider(_userProfile!.profilePictureUrl!)
                : null,
            child: _userProfile?.profilePictureUrl == null
                ? const Icon(
                    Icons.person,
                    size: 40,
                    color: AppColors.customerPrimary,
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
                    color: AppColors.customerPrimaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Customer',
                    style: AppTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.customerPrimary,
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
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return _buildStatsRowContent('0', '0');
        }

        final customerId = authState.userId;

        return BlocBuilder<OrderBloc, OrderState>(
          builder: (context, orderState) {
            if (orderState is OrderLoaded) {
              // Filter orders for this customer
              final customerOrders = orderState.orders
                  .where((o) => o.customerId == customerId)
                  .toList();

              // Count unique vendors (farmers) the customer has ordered from
              final uniqueVendors = customerOrders
                  .map((o) => o.farmerId)
                  .toSet()
                  .length;

              return _buildStatsRowContent(
                customerOrders.length.toString(),
                uniqueVendors.toString(),
              );
            }
            return _buildStatsRowContent('0', '0');
          },
        );
      },
    );
  }

  Widget _buildStatsRowContent(String ordersCount, String vendorsCount) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(ordersCount, 'Orders')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(vendorsCount, 'Vendors')),
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
