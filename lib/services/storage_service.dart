import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/cloudinary_config.dart';
import '../core/errors/app_exception.dart';

/// Handles image uploads to Cloudinary via base64 data URI.
///
/// Uses base64 encoding instead of multipart form, which works correctly
/// on Flutter Web (the http package's multipart upload is unreliable in browsers).
///
/// Images are stored on Cloudinary and only the resulting HTTPS URL
/// is persisted in Firestore.
class StorageService {
  final _uuid = const Uuid();

  /// Uploads [file] for a task and returns the public download URL.
  Future<String> uploadTaskImage({
    required String taskId,
    required XFile file,
    void Function(double progress)? onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    return uploadTaskImageBytes(
      taskId: taskId,
      bytes: bytes,
      onProgress: onProgress,
    );
  }

  /// Uploads raw bytes for a task and returns the public download URL.
  Future<String> uploadTaskImageBytes({
    required String taskId,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    return _uploadBytes(
      bytes: bytes,
      folder: 'wardclean/tasks/$taskId',
      onProgress: onProgress,
    );
  }

  /// Uploads [file] for an issue and returns the public download URL.
  Future<String> uploadIssueImage({
    required String issueId,
    required XFile file,
    void Function(double progress)? onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    return uploadIssueImageBytes(
      issueId: issueId,
      bytes: bytes,
      onProgress: onProgress,
    );
  }

  /// Uploads raw bytes for an issue and returns the public download URL.
  Future<String> uploadIssueImageBytes({
    required String issueId,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    return _uploadBytes(
      bytes: bytes,
      folder: 'wardclean/issues/$issueId',
      onProgress: onProgress,
    );
  }

  Future<String> _uploadBytes({
    required Uint8List bytes,
    required String folder,
    void Function(double progress)? onProgress,
  }) async {
    try {
      onProgress?.call(0.2);

      // Encode image as base64 data URI — works reliably on Flutter web and mobile.
      final base64Image = base64Encode(bytes);
      final dataUri = 'data:image/jpeg;base64,$base64Image';

      onProgress?.call(0.5);

      final publicId = _uuid.v4();
      final uri = Uri.parse(CloudinaryConfig.uploadUrl);

      // Use URL-encoded body — avoids multipart boundary issues on Flutter web.
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'file': dataUri,
          'upload_preset': CloudinaryConfig.uploadPreset,
          'folder': folder,
          'public_id': publicId,
        },
      );

      onProgress?.call(1.0);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final secureUrl = data['secure_url'] as String?;
        if (secureUrl != null && secureUrl.isNotEmpty) {
          return secureUrl;
        }
        throw AppException('Upload succeeded but no image URL was returned.');
      } else {
        final Map<String, dynamic>? errorJson = () {
          try {
            return jsonDecode(response.body) as Map<String, dynamic>?;
          } catch (_) {
            return null;
          }
        }();
        final message = errorJson?['error']?['message'] ??
            'Upload failed (HTTP ${response.statusCode}): ${response.body}';
        throw AppException('Cloudinary upload error: $message');
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(
          'Unable to upload image. Please check your connection.\nDetails: $e');
    }
  }
}
