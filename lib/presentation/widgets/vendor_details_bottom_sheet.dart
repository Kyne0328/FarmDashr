import 'package:flutter/material.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/data/models/user_profile.dart';

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
                Text(farmName, style: AppTextStyles.h3),
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
                              image: NetworkImage(vendor.profilePictureUrl!),
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

                  // About Section
                  Text('About', style: AppTextStyles.h4),
                  const SizedBox(height: AppDimensions.spacingS),
                  Text(description, style: AppTextStyles.body2Secondary),
                  const SizedBox(height: AppDimensions.spacingL),

                  // Contact Info
                  if (vendor.phone != null) ...[
                    _buildContactRow(Icons.phone_outlined, vendor.phone!),
                    const SizedBox(height: AppDimensions.spacingS),
                  ],
                  _buildContactRow(Icons.email_outlined, vendor.email),
                  const SizedBox(height: AppDimensions.spacingXXL),

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
                  OutlinedButton(
                    onPressed: () {
                      // Handle contact
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusM,
                        ),
                      ),
                    ),
                    child: const Text('Contact Vendor'),
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

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body2Secondary,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
