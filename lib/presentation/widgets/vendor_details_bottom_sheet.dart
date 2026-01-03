import 'package:farmdashr/data/models/auth/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:cached_network_image/cached_network_image.dart';

class VendorDetailsBottomSheet extends StatelessWidget {
  final UserProfile vendor;
  final VoidCallback onViewProducts;

  const VendorDetailsBottomSheet({
    super.key,
    required this.vendor,
    required this.onViewProducts,
  });

  @override
  Widget build(BuildContext context) {
    final businessInfo = vendor.businessInfo;
    final farmName = businessInfo?.farmName ?? vendor.name;
    final description =
        businessInfo?.description ??
        "Local producer committed to quality and sustainability.";

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle and Close
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(farmName, style: AppTextStyles.h3)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vendor Image
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusL,
                      ),
                      image: vendor.profilePictureUrl != null
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(
                                vendor.profilePictureUrl!,
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: vendor.profilePictureUrl == null
                        ? const Icon(
                            Icons.store,
                            size: 64,
                            color: AppColors.textTertiary,
                          )
                        : null,
                  ),
                  const SizedBox(height: AppDimensions.spacingM),

                  // Certifications Badges
                  if (businessInfo?.certifications.isNotEmpty ?? false) ...[
                    _buildCertificationBadges(businessInfo!.certifications),
                    const SizedBox(height: AppDimensions.spacingM),
                  ],

                  // About Section
                  Text('About', style: AppTextStyles.h4),
                  const SizedBox(height: AppDimensions.spacingS),
                  Text(description, style: AppTextStyles.body2Secondary),
                  const SizedBox(height: AppDimensions.spacingL),

                  // Operating Hours
                  if (businessInfo?.operatingHours != null &&
                      businessInfo!.operatingHours!.isNotEmpty) ...[
                    _buildInfoRow(
                      icon: Icons.schedule_outlined,
                      label: 'Operating Hours',
                      value: businessInfo.operatingHours!,
                    ),
                    const SizedBox(height: AppDimensions.spacingM),
                  ],

                  // Business License
                  if (businessInfo?.businessLicense != null &&
                      businessInfo!.businessLicense!.isNotEmpty) ...[
                    _buildInfoRow(
                      icon: Icons.verified_outlined,
                      label: 'Licensed Business',
                      value: businessInfo.businessLicense!,
                    ),
                    const SizedBox(height: AppDimensions.spacingM),
                  ],

                  // Social Media Links
                  if (_hasSocialLinks(businessInfo)) ...[
                    const SizedBox(height: AppDimensions.spacingS),
                    Text('Connect', style: AppTextStyles.h4),
                    const SizedBox(height: AppDimensions.spacingS),
                    _buildSocialLinks(businessInfo!),
                    const SizedBox(height: AppDimensions.spacingL),
                  ],

                  const SizedBox(height: AppDimensions.spacingM),

                  // Action Buttons
                  ElevatedButton(
                    onPressed: onViewProducts,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusM,
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('View All Products'),
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationBadges(List<Certification> certifications) {
    return Wrap(
      spacing: AppDimensions.spacingS,
      runSpacing: AppDimensions.spacingS,
      children: certifications
          .where((cert) => cert.isValid)
          .map((cert) => _buildCertBadge(cert))
          .toList(),
    );
  }

  Widget _buildCertBadge(Certification cert) {
    final color = _getCertColor(cert.type);
    final icon = _getCertIcon(cert.type);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(
            cert.name,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCertColor(CertificationType type) {
    switch (type) {
      case CertificationType.organic:
        return AppColors.success;
      case CertificationType.local:
        return AppColors.primary;
      case CertificationType.nonGmo:
        return Colors.purple;
      case CertificationType.fairTrade:
        return Colors.orange;
      case CertificationType.other:
        return AppColors.textSecondary;
    }
  }

  IconData _getCertIcon(CertificationType type) {
    switch (type) {
      case CertificationType.organic:
        return Icons.eco;
      case CertificationType.local:
        return Icons.location_on;
      case CertificationType.nonGmo:
        return Icons.science;
      case CertificationType.fairTrade:
        return Icons.handshake;
      case CertificationType.other:
        return Icons.verified;
    }
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingS),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: AppTextStyles.body2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasSocialLinks(BusinessInfo? businessInfo) {
    if (businessInfo == null) return false;
    return (businessInfo.facebookUrl != null &&
            businessInfo.facebookUrl!.isNotEmpty) ||
        (businessInfo.instagramUrl != null &&
            businessInfo.instagramUrl!.isNotEmpty);
  }

  Widget _buildSocialLinks(BusinessInfo businessInfo) {
    return Row(
      children: [
        if (businessInfo.facebookUrl != null &&
            businessInfo.facebookUrl!.isNotEmpty)
          _buildSocialButton(
            icon: Icons.facebook,
            label: 'Facebook',
            color: const Color(0xFF1877F2),
            url: businessInfo.facebookUrl!,
          ),
        if (businessInfo.facebookUrl != null &&
            businessInfo.facebookUrl!.isNotEmpty &&
            businessInfo.instagramUrl != null &&
            businessInfo.instagramUrl!.isNotEmpty)
          const SizedBox(width: AppDimensions.spacingM),
        if (businessInfo.instagramUrl != null &&
            businessInfo.instagramUrl!.isNotEmpty)
          _buildSocialButton(
            icon: Icons.camera_alt,
            label: 'Instagram',
            color: const Color(0xFFE4405F),
            url: businessInfo.instagramUrl!,
          ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required String url,
  }) {
    return Expanded(
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: InkWell(
          onTap: () => _launchUrl(url),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.paddingM,
              horizontal: AppDimensions.paddingS,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  label,
                  style: AppTextStyles.labelMedium.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await launcher.canLaunchUrl(uri)) {
      await launcher.launchUrl(
        uri,
        mode: launcher.LaunchMode.externalApplication,
      );
    }
  }
}
