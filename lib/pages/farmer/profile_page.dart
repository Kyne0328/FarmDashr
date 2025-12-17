import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Core constants
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';

// Data models
import 'package:farmdashr/data/models/user_profile.dart';

// Shared widgets
import 'package:farmdashr/presentation/widgets/common/stat_card.dart';
import 'package:farmdashr/presentation/widgets/common/status_badge.dart';
import 'package:farmdashr/pages/farmer/farmer_bottom_nav_bar.dart';

/// Profile Page - refactored to use SOLID principles.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Using sample data from UserProfile model
    final profile = UserProfile.sampleFarmer;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text('Profile', style: AppTextStyles.h3),
                    const SizedBox(height: AppDimensions.spacingL),

                    // Profile Card
                    _ProfileCard(profile: profile),
                    const SizedBox(height: AppDimensions.spacingL),

                    // Stats Row - using shared StatCard
                    _buildStatsRow(profile),
                    const SizedBox(height: AppDimensions.spacingL),

                    // Business Information Card
                    _BusinessInfoCard(profile: profile),
                    const SizedBox(height: AppDimensions.spacingL),

                    // Logout Button
                    _LogoutButton(onTap: () => context.go('/')),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Bar - using shared widget
            const FarmerBottomNavBar(currentItem: FarmerNavItem.profile),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(UserProfile profile) {
    final stats = profile.stats ?? UserStats.sampleFarmerStats;

    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.attach_money,
            title: 'Total Revenue',
            value: stats.formattedRevenue,
            change: stats.formattedRevenueChange,
            theme: const SuccessStatCardTheme(),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingL),
        Expanded(
          child: StatCard(
            icon: Icons.shopping_bag_outlined,
            title: 'Products Sold',
            value: stats.formattedProductsSold,
            change: stats.formattedProductsSoldChange,
            theme: const InfoStatCardTheme(),
          ),
        ),
      ],
    );
  }
}

// Private widgets

class _ProfileCard extends StatelessWidget {
  final UserProfile profile;

  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingXXXL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(
          color: AppColors.border,
          width: AppDimensions.borderWidthThick,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header with Avatar
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: AppDimensions.avatarL,
                height: AppDimensions.avatarL,
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.person, size: 40, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingL),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.name, style: AppTextStyles.body1),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(profile.email, style: AppTextStyles.body2Secondary),
                    const SizedBox(height: AppDimensions.spacingS),
                    // Account Type Badge - using shared StatusBadge
                    StatusBadge.accountType(
                      label: profile.userType.displayName,
                    ),
                  ],
                ),
              ),
              // Edit Button
              GestureDetector(
                onTap: () {
                  // TODO: Navigate to edit profile
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: AppDimensions.iconM,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingL),
          // Contact Information
          if (profile.phone != null)
            _ContactRow(icon: Icons.phone_outlined, text: profile.phone!),
          if (profile.phone != null)
            const SizedBox(height: AppDimensions.spacingS),
          _ContactRow(icon: Icons.email_outlined, text: profile.email),
          const SizedBox(height: AppDimensions.spacingS),
          if (profile.address != null)
            _ContactRow(
              icon: Icons.location_on_outlined,
              text: profile.address!,
            ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppDimensions.iconS, color: AppColors.textTertiary),
        const SizedBox(width: AppDimensions.spacingS),
        Text(text, style: AppTextStyles.body2Tertiary),
      ],
    );
  }
}

class _BusinessInfoCard extends StatelessWidget {
  final UserProfile profile;

  const _BusinessInfoCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final businessInfo = profile.businessInfo ?? BusinessInfo.sample;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingXL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(
          color: AppColors.border,
          width: AppDimensions.borderWidthThick,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: AppDimensions.iconM,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Text('Business Information', style: AppTextStyles.body1),
                ],
              ),
              GestureDetector(
                onTap: () {
                  // TODO: Navigate to edit business info
                },
                child: Text('Edit', style: AppTextStyles.link),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),

          // Business Info Fields
          _InfoField(label: 'Farm Name', value: businessInfo.farmName),
          const SizedBox(height: AppDimensions.spacingM),
          if (businessInfo.businessLicense != null) ...[
            _InfoField(
              label: 'Business License',
              value: businessInfo.businessLicense!,
            ),
            const SizedBox(height: AppDimensions.spacingM),
          ],

          // Certifications
          Text('Certification', style: AppTextStyles.body2Secondary),
          const SizedBox(height: AppDimensions.spacingXS),
          Row(
            children: businessInfo.certifications.map((cert) {
              final type = cert.type == CertificationType.organic
                  ? CertificationBadgeType.organic
                  : CertificationBadgeType.local;
              return Padding(
                padding: const EdgeInsets.only(right: AppDimensions.spacingS),
                child: StatusBadge.certification(label: cert.name, type: type),
              );
            }).toList(),
          ),
          const SizedBox(height: AppDimensions.spacingM),

          // Member Since
          _InfoField(
            label: 'Member Since',
            value: profile.formattedMemberSince,
          ),
        ],
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;

  const _InfoField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.body2Secondary),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(value, style: AppTextStyles.body2),
      ],
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.logout,
              size: AppDimensions.iconM,
              color: Colors.white,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Text('Logout', style: AppTextStyles.button),
          ],
        ),
      ),
    );
  }
}
