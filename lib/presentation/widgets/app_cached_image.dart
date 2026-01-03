import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:farmdashr/core/constants/app_colors.dart';

/// A reusable cached network image widget with consistent styling.
/// Provides loading placeholder and error fallback.
class AppCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.borderLight,
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: AppColors.borderLight,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

/// Creates a cached DecorationImage for use in BoxDecoration.
/// Returns null if imageUrl is null or empty.
DecorationImage? cachedDecorationImage(
  String? imageUrl, {
  BoxFit fit = BoxFit.cover,
}) {
  if (imageUrl == null || imageUrl.isEmpty) return null;
  return DecorationImage(image: CachedNetworkImageProvider(imageUrl), fit: fit);
}

/// Creates a cached ImageProvider for use in CircleAvatar.backgroundImage.
ImageProvider? cachedImageProvider(String? imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty) return null;
  return CachedNetworkImageProvider(imageUrl);
}
