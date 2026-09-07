import 'package:firebase_auth/firebase_auth.dart';

/// A user-facing exception with a friendly message. Every service layer
/// call should throw this (never a raw FirebaseException) so screens can
/// show `e.message` directly without leaking technical detail (PRD §38).
class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => message;
}

/// Converts FirebaseAuthException codes into friendly copy (PRD §7).
AppException mapAuthError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return AppException('That email address doesn\'t look right.');
      case 'user-not-found':
        return AppException('No account found with that email.');
      case 'wrong-password':
      case 'invalid-credential':
        return AppException('Incorrect email or password.');
      case 'user-disabled':
        return AppException(
            'This account has been disabled. Contact your supervisor.');
      case 'email-already-in-use':
        return AppException('An account with this email already exists.');
      case 'weak-password':
        return AppException(
            'Password is too weak. Use at least 6 characters.');
      case 'network-request-failed':
        return AppException(
            'Network error. Check your connection and try again.');
      case 'too-many-requests':
        return AppException(
            'Too many attempts. Please wait a moment and try again.');
      default:
        return AppException('Unable to sign in. Please try again.');
    }
  }
  return AppException('Something went wrong. Please try again.');
}

/// Converts Firestore/Storage errors into friendly copy (PRD §38).
AppException mapFirestoreError(Object error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return AppException(
            'You don\'t have permission to do that.');
      case 'unavailable':
        return AppException(
            'Unable to reach the server. Check your connection.');
      case 'not-found':
        return AppException('The requested record was not found.');
      default:
        return AppException('Unable to save. Please try again.');
    }
  }
  return AppException('Unable to save. Please try again.');
}
