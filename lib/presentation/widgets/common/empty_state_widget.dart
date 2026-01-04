import 'package:flutter/material.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/presentation/widgets/common/farm_button.dart';

/// A polished empty state widget with illustration, title, subtitle, and optional CTA.
///
/// Use this widget to display consistent, visually appealing empty states
/// across the app for carts, orders, products, notifications, etc.
class EmptyStateWidget extends StatelessWidget {
  /// Icon to display in the illustration circle
  final IconData icon;

  /// Primary title text
  final String title;

  /// Secondary descriptive text
  final String subtitle;

  /// Optional call-to-action button text
  final String? actionText;

  /// Optional callback when CTA button is pressed
  final VoidCallback? onAction;

  /// Optional custom icon color (defaults to textSecondary)
  final Color? iconColor;

  /// Optional custom icon background color (defaults to borderLight)
  final Color? iconBackgroundColor;

  /// Optional emoji to display instead of icon
  final String? emoji;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
    this.iconColor,
    this.iconBackgroundColor,
    this.emoji,
  });

  // Factory constructors for common empty states

  /// Empty shopping cart
  factory EmptyStateWidget.cart({VoidCallback? onBrowse}) {
    return EmptyStateWidget(
      icon: Icons.shopping_cart_outlined,
      emoji: '🛒',
      title: 'Your cart is empty',
      subtitle: 'Explore our fresh local produce and add some items!',
      actionText: 'Browse Products',
      onAction: onBrowse,
      iconColor: AppColors.info,
      iconBackgroundColor: AppColors.infoLight,
    );
  }

  /// No products found
  factory EmptyStateWidget.noProducts({
    String? searchQuery,
    String? categoryName,
    VoidCallback? onClearFilters,
  }) {
    final hasFilters = searchQuery?.isNotEmpty == true || categoryName != null;

    String title;
    if (categoryName != null && searchQuery?.isNotEmpty == true) {
      title = 'No $categoryName matching "$searchQuery"';
    } else if (categoryName != null) {
      title = 'No $categoryName available';
    } else if (searchQuery?.isNotEmpty == true) {
      title = 'No products matching "$searchQuery"';
    } else {
      title = 'No products available';
    }

    return EmptyStateWidget(
      icon: hasFilters ? Icons.search_off_rounded : Icons.inventory_2_outlined,
      emoji: hasFilters ? '🔍' : '📦',
      title: title,
      subtitle: hasFilters
          ? 'Try adjusting your filters or search terms'
          : 'Check back later for fresh produce!',
      actionText: hasFilters ? 'Clear Filters' : null,
      onAction: onClearFilters,
      iconColor: AppColors.textSecondary,
    );
  }

  /// No vendors found
  factory EmptyStateWidget.noVendors({String? searchQuery}) {
    final hasSearch = searchQuery?.isNotEmpty == true;

    return EmptyStateWidget(
      icon: Icons.store_outlined,
      emoji: '🏪',
      title: hasSearch
          ? 'No vendors matching "$searchQuery"'
          : 'No vendors found',
      subtitle: hasSearch
          ? 'Try adjusting your search terms'
          : 'Check back later for more local producers!',
      iconColor: AppColors.textSecondary,
    );
  }

  /// Empty orders (customer)
  factory EmptyStateWidget.noOrders({VoidCallback? onBrowse}) {
    return EmptyStateWidget(
      icon: Icons.receipt_long_outlined,
      emoji: '📋',
      title: 'No orders yet',
      subtitle: 'Your order history will appear here once you make a purchase',
      actionText: 'Start Shopping',
      onAction: onBrowse,
      iconColor: AppColors.info,
      iconBackgroundColor: AppColors.infoLight,
    );
  }

  /// Empty inventory (farmer)
  factory EmptyStateWidget.emptyInventory({VoidCallback? onAddProduct}) {
    return EmptyStateWidget(
      icon: Icons.inventory_2_outlined,
      emoji: '🌱',
      title: 'Your inventory is empty',
      subtitle: 'Add your first product to start selling to customers',
      actionText: 'Add Product',
      onAction: onAddProduct,
      iconColor: AppColors.primary,
      iconBackgroundColor: AppColors.primaryLight,
    );
  }

  /// No notifications
  factory EmptyStateWidget.noNotifications() {
    return EmptyStateWidget(
      icon: Icons.notifications_none_outlined,
      emoji: '🔔',
      title: 'No notifications yet',
      subtitle: 'You\'ll see updates about your orders and offers here',
      iconColor: AppColors.textSecondary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration Circle with Icon/Emoji
            _buildIllustration(),
            const SizedBox(height: AppDimensions.spacingXL),

            // Title
            Text(
              title,
              style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingS),

            // Subtitle
            Text(
              subtitle,
              style: AppTextStyles.body2Secondary.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),

            // CTA Button (optional)
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppDimensions.spacingXL),
              FarmButton(
                label: actionText!,
                onPressed: onAction!,
                style: FarmButtonStyle.primary,
                height: 48,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    final bgColor = iconBackgroundColor ?? AppColors.borderLight;
    final fgColor = iconColor ?? AppColors.textSecondary;

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Decorative ring
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: fgColor.withValues(alpha: 0.15),
                width: 2,
              ),
            ),
          ),
          // Main icon or emoji
          if (emoji != null)
            Text(emoji!, style: const TextStyle(fontSize: 48))
          else
            Icon(icon, size: 48, color: fgColor),
        ],
      ),
    );
  }
}
