/// Cloudinary configuration for unsigned image uploads.
///
/// Cloudinary provides 25 GB of free monthly storage and bandwidth with no credit card required.
///
/// To use your own Cloudinary account:
/// 1. Create a free account at https://cloudinary.com
/// 2. Go to Settings -> Upload -> Upload presets
/// 3. Add an upload preset, set "Signing Mode" to "Unsigned"
/// 4. Put your Cloud Name and Upload Preset name below.
class CloudinaryConfig {
  CloudinaryConfig._();

  /// Your Cloudinary Cloud Name.
  /// Replace with your Cloudinary cloud name.
  static const String cloudName = 'dhlq1ward';

  /// Your Cloudinary Unsigned Upload Preset.
  /// Replace with your unsigned upload preset name.
  static const String uploadPreset = 'wardclean_unsigned';

  /// Base URL for Cloudinary image upload API.
  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
}
