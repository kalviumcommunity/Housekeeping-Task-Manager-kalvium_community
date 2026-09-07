import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import 'auth_service.dart';

enum AuthStatus { loading, signedOut, signedIn, profileMissing }

/// Single source of truth for "who is logged in / what's their role".
/// Screens/navigation read this via Provider instead of talking to
/// FirebaseAuth directly (PRD §36 — auth guards, splash-while-resolving).
class AppState extends ChangeNotifier {
  final AuthService _authService;
  final UserRepository _userRepository;

  AppState({AuthService? authService, UserRepository? userRepository})
      : _authService = authService ?? AuthService(),
        _userRepository = userRepository ?? UserRepository() {
    _authSub = _authService.authStateChanges.listen(_onAuthChanged);
  }

  AuthStatus status = AuthStatus.loading;
  UserModel? currentUser;
  String? lastError;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<UserModel?>? _profileSub;

  Future<void> _onAuthChanged(User? user) async {
    await _profileSub?.cancel();

    if (user == null) {
      status = AuthStatus.signedOut;
      currentUser = null;
      notifyListeners();
      return;
    }

    // Keep the profile live so role/active changes reflect immediately.
    _profileSub = _userRepository.watchUser(user.uid).listen((profile) {
      if (profile == null) {
        status = AuthStatus.profileMissing;
        currentUser = null;
      } else if (!profile.active) {
        // Deactivated users are treated as signed out (PRD §6, §38).
        status = AuthStatus.profileMissing;
        currentUser = null;
        lastError = 'Your account has been deactivated. Contact your supervisor.';
        _authService.signOut();
      } else {
        status = AuthStatus.signedIn;
        currentUser = profile;
      }
      notifyListeners();
    }, onError: (_) {
      status = AuthStatus.profileMissing;
      currentUser = null;
      notifyListeners();
    });
  }

  Future<void> signOut() => _authService.signOut();

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
