import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/enums.dart';
import '../core/constants/firestore_paths.dart';
import '../core/errors/app_exception.dart';
import '../models/issue_model.dart';

/// Firestore access for `issues/{issueId}` (PRD §12, §19, §27, §29).
class IssueRepository {
  final FirebaseFirestore _db;

  IssueRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.issues);

  Stream<List<IssueModel>> watchByStatus(IssueStatus status) {
    return _col
        .where('status', isEqualTo: status.value)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(IssueModel.fromFirestore).toList());
  }

  /// Issues reported by a specific user (employee's own "Issues" tab).
  Stream<List<IssueModel>> watchByReporter(String uid) {
    return _col
        .where('reportedBy', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(IssueModel.fromFirestore).toList());
  }

  Stream<List<IssueModel>> watchAll() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(IssueModel.fromFirestore).toList());
  }

  /// PRD §29 — recent issue history used as the raw input to recurring
  /// issue detection. The grouping/threshold logic itself lives in
  /// `ComplianceService` (kept separate so it's independently testable).
  Stream<List<IssueModel>> watchRecent({required int days}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _col
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(IssueModel.fromFirestore).toList());
  }

  /// One-time fetch equivalent of [watchRecent], used by report screens
  /// that don't need a live stream.
  Future<List<IssueModel>> getRecentIssues({required int days}) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: days));
      final snap = await _col
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map(IssueModel.fromFirestore).toList();
    } on FirebaseException catch (e) {
      throw mapFirestoreError(e);
    }
  }

  Future<List<IssueModel>> getIssuesForDate(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      final snap = await _col
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end))
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map(IssueModel.fromFirestore).toList();
    } on FirebaseException catch (e) {
      throw mapFirestoreError(e);
    }
  }

  Future<IssueModel> createIssue(IssueModel issue) async {
    try {
      final ref = await _col.add(issue.toFirestoreCreate());
      final doc = await ref.get();
      return IssueModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw mapFirestoreError(e);
    }
  }

  /// Attaches an image URL after a Storage upload completes (PRD §20).
  Future<void> attachImage({required String issueId, required String imageUrl}) async {
    try {
      await _col.doc(issueId).update({'imageUrl': imageUrl});
    } on FirebaseException catch (e) {
      throw mapFirestoreError(e);
    }
  }

  /// PRD §27 — resolve issue (supervisor only; enforced by security rules).
  Future<void> resolveIssue(String issueId) async {
    try {
      await _col.doc(issueId).update({
        'status': IssueStatus.resolved.value,
        'resolvedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw mapFirestoreError(e);
    }
  }
}
