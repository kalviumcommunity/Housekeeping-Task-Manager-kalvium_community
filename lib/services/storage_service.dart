import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/firestore_paths.dart';
import '../core/errors/app_exception.dart';

/// Handles image uploads to Firebase Storage (PRD §20).
/// Images are never stored as binary in Firestore — only the resulting
/// download URL is persisted there.
class StorageService {
  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Uploads [file] for a task and returns the public download URL.
  /// Throws [AppException] on failure; caller is responsible for
  /// preserving form state so the user can retry (PRD §20).
  Future<String> uploadTaskImage({
    required String taskId,
    required File file,
    void Function(double progress)? onProgress,
  }) {
    final fileName = '${_uuid.v4()}${_extensionOf(file.path)}';
    final path = StoragePaths.taskImage(taskId, fileName);
    return _upload(path: path, file: file, onProgress: onProgress);
  }

  /// Uploads [file] for an issue and returns the public download URL.
  Future<String> uploadIssueImage({
    required String issueId,
    required File file,
    void Function(double progress)? onProgress,
  }) {
    final fileName = '${_uuid.v4()}${_extensionOf(file.path)}';
    final path = StoragePaths.issueImage(issueId, fileName);
    return _upload(path: path, file: file, onProgress: onProgress);
  }

  Future<String> _upload({
    required String path,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final task = ref.putFile(
        file,
        SettableMetadata(contentType: _contentTypeOf(file.path)),
      );

      if (onProgress != null) {
        task.snapshotEvents.listen((snapshot) {
          if (snapshot.totalBytes > 0) {
            onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
          }
        });
      }

      final snapshot = await task;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException {
      throw AppException(
          'Unable to upload image. Please check your connection and try again.');
    } catch (_) {
      throw AppException('Unable to upload image. Please try again.');
    }
  }

  String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1) return '.jpg';
    return path.substring(dot);
  }

  String _contentTypeOf(String path) {
    final ext = _extensionOf(path).toLowerCase();
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }
}
