import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:farmdashr/core/constants/app_colors.dart';
import 'package:farmdashr/core/constants/app_text_styles.dart';
import 'package:farmdashr/data/models/product/product.dart';

class ProductImage extends StatelessWidget {
  final Product product;
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;
  final bool useHero;

  const ProductImage({
    super.key,
    required this.product,
    this.height,
    this.width,
    this.borderRadius,
    this.useHero = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageContent = Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.borderLight,
        borderRadius: borderRadius,
        image: product.imageUrls.isNotEmpty
            ? DecorationImage(
                image: CachedNetworkImageProvider(product.imageUrls.first),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: product.imageUrls.isEmpty
          ? const Center(
              child: Icon(
                Icons.shopping_basket,
                color: AppColors.textSecondary,
              ),
            )
          : null,
    );

    if (useHero) {
      imageContent = Hero(
        tag: 'product_image_${product.id}',
        child: imageContent,
      );
    }

    return Stack(
      children: [
        imageContent,
        // Stock Badge
        if (product.currentStock == 0)
          Positioned(
            top: 8,
            left: 8,
            child: _buildBadge(text: 'Out of Stock', color: AppColors.error),
          )
        else if (product.isLowStock)
          Positioned(
            top: 8,
            left: 8,
            child: _buildBadge(text: 'Low Stock', color: AppColors.warning),
          ),
      ],
    );
  }

  Widget _buildBadge({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
