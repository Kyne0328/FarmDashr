import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:farmdashr/core/constants/cloudinary_configs.dart';

/// Service for uploading images to Cloudinary.
class CloudinaryService {
  final Dio _dio = Dio();

  /// Uploads multiple images to Cloudinary and returns their URLs.
  Future<List<String>> uploadImages(List<XFile> images) async {
    if (images.isEmpty) return [];

    final List<String> imageUrls = [];

    for (final image in images) {
      final url = await uploadImage(image);
      if (url != null) {
        imageUrls.add(url);
      }
    }

    return imageUrls;
  }

  /// Uploads a single image to Cloudinary and returns its URL.
  Future<String?> uploadImage(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: image.name),
        'upload_preset': CloudinaryConfigs.uploadPreset,
      });

      final response = await _dio.post(
        CloudinaryConfigs.uploadUrl,
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data['secure_url'] as String;
      }
      return null;
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      return null;
    }
  }
}
