import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_paths.dart';
import '../core/errors/app_exception.dart';
import '../models/ward_model.dart';

/// Firestore access for `wards/{wardId}` (PRD §10).
class WardRepository {
  final FirebaseFirestore _db;

  WardRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.wards);

  Stream<List<WardModel>> watchActiveWards() {
    return _col.where('active', isEqualTo: true).snapshots().map(
          (snap) => snap.docs.map(WardModel.fromFirestore).toList()
            ..sort((a, b) => a.wardName.compareTo(b.wardName)),
        );
  }

  Future<List<WardModel>> getActiveWards() async {
    try {
      final snap = await _col.where('active', isEqualTo: true).get();
      final wards = snap.docs.map(WardModel.fromFirestore).toList()
        ..sort((a, b) => a.wardName.compareTo(b.wardName));
      return wards;
    } on FirebaseException catch (e) {
      throw mapFirestoreError(e);
    }
  }
}
