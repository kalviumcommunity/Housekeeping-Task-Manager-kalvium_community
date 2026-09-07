import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_paths.dart';
import '../core/errors/app_exception.dart';
import '../models/user_model.dart';

/// Firestore access for `users/{uid}` (PRD §9, §23).
class UserRepository {
  final FirebaseFirestore _db;

  UserRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.users);

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _col.doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw mapFirestoreError(e);
    }
  }

  Stream<UserModel?> watchUser(String uid) {
    return _col.doc(uid).snapshots().map(
          (doc) => doc.exists ? UserModel.fromFirestore(doc) : null,
        );
  }

  /// Creates the user's Firestore profile after Firebase Auth registration.
  /// Role is always forced to `employee` here — supervisors are provisioned
  /// manually (PRD §6) and this path must never allow self-elevation.
  Future<void> createEmployeeProfile(UserModel user) async {
    try {
      await _col.doc(user.uid).set(user.toFirestore(isCreate: true));
    } on FirebaseException catch (e) {
      throw mapFirestoreError(e);
    }
  }

  /// PRD §23 — active employees for the assignment dropdown.
  Stream<List<UserModel>> watchActiveEmployees() {
    return _col
        .where('role', isEqualTo: 'employee')
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map(UserModel.fromFirestore).toList());
  }
}
