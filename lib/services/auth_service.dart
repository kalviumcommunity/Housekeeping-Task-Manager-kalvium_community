import 'package:firebase_auth/firebase_auth.dart';
import '../core/errors/app_exception.dart';

/// Thin wrapper around FirebaseAuth. Never swallows failures silently —
/// every method either succeeds or throws an [AppException] with a
/// friendly message (PRD §7, §38).
class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// Emits on every auth state change (login, logout, app restart).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<User> signIn({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw AppException('Unable to sign in. Please try again.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw mapAuthError(e);
    } catch (e) {
      throw mapAuthError(e);
    }
  }

  /// Employee self-registration (PRD §7). Supervisors are pre-created
  /// (PRD §6) and must NOT be created through this method.
  Future<User> registerEmployee({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw AppException('Unable to create account. Please try again.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw mapAuthError(e);
    } catch (e) {
      throw mapAuthError(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
