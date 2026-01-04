import 'package:flutter/material.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_dimensions.dart';

/// A shimmer-animated loading placeholder widget.
///
/// Use this widget to create polished skeleton loaders that match
/// the layout of actual content, providing better loading UX.
class ShimmerLoader extends StatefulWidget {
  final Widget child;

  const ShimmerLoader({super.key, required this.child});

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFFE5E7EB),
                Color(0xFFF3F4F6),
                Color(0xFFE5E7EB),
              ],
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
              transform: const GradientRotation(0.5),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

/// A simple shimmer box placeholder
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Pre-built skeleton loaders for common layouts
class SkeletonLoaders {
  SkeletonLoaders._();

  /// Horizontal product card skeleton (for home page carousels)
  static Widget productCard() {
    return ShimmerLoader(
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.radiusL),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingS),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 100, height: 14, borderRadius: 4),
                  const SizedBox(height: 6),
                  ShimmerBox(width: 60, height: 10, borderRadius: 4),
                  const SizedBox(height: 8),
                  ShimmerBox(width: 50, height: 14, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Horizontal vendor card skeleton
  static Widget vendorCard() {
    return ShimmerLoader(
      child: Container(
        width: 160,
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.radiusL),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingS),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 100, height: 14, borderRadius: 4),
                  const SizedBox(height: 6),
                  ShimmerBox(width: 60, height: 10, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// List item skeleton (for browse page)
  static Widget listItem() {
    return ShimmerLoader(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Image placeholder
            ShimmerBox(
              width: 80,
              height: 80,
              borderRadius: AppDimensions.radiusS,
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(
                    width: double.infinity,
                    height: 16,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 8),
                  ShimmerBox(width: 120, height: 12, borderRadius: 4),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerBox(width: 60, height: 16, borderRadius: 4),
                      ShimmerBox(width: 70, height: 24, borderRadius: 6),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Order card skeleton
  static Widget orderCard() {
    return ShimmerLoader(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 100, height: 16, borderRadius: 4),
                    const SizedBox(height: 8),
                    ShimmerBox(width: 140, height: 12, borderRadius: 4),
                    const SizedBox(height: 4),
                    ShimmerBox(width: 80, height: 12, borderRadius: 4),
                  ],
                ),
                ShimmerBox(width: 70, height: 24, borderRadius: 12),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
            const SizedBox(height: 8),
            ShimmerBox(width: 200, height: 12, borderRadius: 4),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 40, height: 12, borderRadius: 4),
                ShimmerBox(width: 80, height: 18, borderRadius: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Cart item skeleton
  static Widget cartItem() {
    return ShimmerLoader(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(
              width: 72,
              height: 72,
              borderRadius: AppDimensions.radiusS,
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerBox(width: 120, height: 16, borderRadius: 4),
                      ShimmerBox(width: 20, height: 20, borderRadius: 4),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ShimmerBox(width: 80, height: 12, borderRadius: 4),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerBox(width: 70, height: 16, borderRadius: 4),
                      ShimmerBox(width: 90, height: 32, borderRadius: 6),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Inventory product card skeleton
  static Widget inventoryCard() {
    return ShimmerLoader(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  width: 60,
                  height: 60,
                  borderRadius: AppDimensions.radiusM,
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 140, height: 16, borderRadius: 4),
                      const SizedBox(height: 8),
                      ShimmerBox(width: 100, height: 12, borderRadius: 4),
                    ],
                  ),
                ),
                ShimmerBox(width: 24, height: 24, borderRadius: 4),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Row(
              children: [
                Expanded(
                  child: ShimmerBox(width: 60, height: 40, borderRadius: 4),
                ),
                const SizedBox(width: AppDimensions.spacingL),
                Expanded(
                  child: ShimmerBox(width: 60, height: 40, borderRadius: 4),
                ),
                const SizedBox(width: AppDimensions.spacingL),
                Expanded(
                  child: ShimmerBox(width: 60, height: 40, borderRadius: 4),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingM),
            const Divider(),
            const SizedBox(height: AppDimensions.spacingM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 60, height: 12, borderRadius: 4),
                ShimmerBox(width: 80, height: 16, borderRadius: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Horizontal list loading (multiple cards in a row)
  static Widget horizontalList({
    required Widget Function() cardBuilder,
    int itemCount = 3,
    double height = 220,
  }) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppDimensions.spacingM),
        itemBuilder: (context, index) => cardBuilder(),
      ),
    );
  }

  /// Vertical list loading
  static Widget verticalList({
    required Widget Function() cardBuilder,
    int itemCount = 3,
  }) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppDimensions.spacingM),
      itemBuilder: (context, index) => cardBuilder(),
    );
  }
}
