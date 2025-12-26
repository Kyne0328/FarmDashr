class CloudinaryConfigs {
  static const String cloudName = 'darvat2y6';
  static const String uploadPreset = 'products';

  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
}
