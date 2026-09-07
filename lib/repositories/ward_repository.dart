import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_paths.dart';
import '../models/ward_model.dart';

/// Firestore access for `wards/{wardId}` (PRD §10).
class WardRepository {
  final FirebaseFirestore _db;

  WardRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.wards);

  static final List<WardModel> defaultWards = [
    WardModel(wardId: 'ward_01', wardName: 'Ward 1 (General)', floor: '1st Floor', description: 'General Ward', active: true),
    WardModel(wardId: 'ward_02', wardName: 'Ward 2 (Surgical)', floor: '2nd Floor', description: 'Surgical Ward', active: true),
    WardModel(wardId: 'ward_03', wardName: 'Ward 3 (ICU)', floor: '3rd Floor', description: 'ICU', active: true),
  ];

  Stream<List<WardModel>> watchActiveWards() {
    return _col.where('active', isEqualTo: true).snapshots().map(
          (snap) {
            final list = snap.docs.map(WardModel.fromFirestore).toList();
            if (list.isEmpty) return defaultWards;
            return list..sort((a, b) => a.wardName.compareTo(b.wardName));
          },
        );
  }

  Future<List<WardModel>> getActiveWards() async {
    try {
      final snap = await _col.where('active', isEqualTo: true).get();
      final wards = snap.docs.map(WardModel.fromFirestore).toList()
        ..sort((a, b) => a.wardName.compareTo(b.wardName));
      return wards.isNotEmpty ? wards : defaultWards;
    } catch (_) {
      return defaultWards;
    }
  }
}
