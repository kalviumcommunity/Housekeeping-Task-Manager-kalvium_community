import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/cloudinary_config.dart';
import '../core/errors/app_exception.dart';

/// Handles image uploads to Cloudinary unsigned preset.
///
/// Images are stored securely on Cloudinary and only the resulting
/// public HTTPS URL is persisted in Firestore.
/// Cross-platform: works seamlessly on Web, Android, and iOS using [XFile].
class StorageService {
  final _uuid = const Uuid();

  /// Uploads [file] (an [XFile] from ImagePicker) for a task and returns the public download URL.
  Future<String> uploadTaskImage({
    required String taskId,
    required XFile file,
    void Function(double progress)? onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    return _uploadBytes(
      bytes: bytes,
      fileName: '${_uuid.v4()}_${file.name}',
      folder: 'wardclean/tasks/$taskId',
      onProgress: onProgress,
    );
  }

  /// Uploads [file] (an [XFile] from ImagePicker) for an issue and returns the public download URL.
  Future<String> uploadIssueImage({
    required String issueId,
    required XFile file,
    void Function(double progress)? onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    return _uploadBytes(
      bytes: bytes,
      fileName: '${_uuid.v4()}_${file.name}',
      folder: 'wardclean/issues/$issueId',
      onProgress: onProgress,
    );
  }

  Future<String> _uploadBytes({
    required Uint8List bytes,
    required String fileName,
    required String folder,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final uri = Uri.parse(CloudinaryConfig.uploadUrl);
      final request = http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
      request.fields['folder'] = folder;

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );

      if (onProgress != null) {
        onProgress(0.5);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (onProgress != null) {
        onProgress(1.0);
      }

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
            'Upload failed (HTTP ${response.statusCode})';
        throw AppException('Cloudinary upload error: $message');
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(
          'Unable to upload image ($e). Please check your connection.');
    }
  }
}
