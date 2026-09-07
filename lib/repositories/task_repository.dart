import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/enums.dart';
import '../core/constants/firestore_paths.dart';
import '../core/errors/app_exception.dart';
import '../models/task_model.dart';

/// Filters supported by the supervisor Tasks screen (PRD §25, §33).
class TaskFilter {
  final String? wardId;
  final TaskStatus? status;
  final TaskType? taskType;
  final String? employeeUid;
  final DateTime? date; // filters by createdAt's calendar day

  const TaskFilter({
    this.wardId,
    this.status,
    this.taskType,
    this.employeeUid,
    this.date,
  });

  bool get isEmpty =>
      wardId == null &&
      status == null &&
      taskType == null &&
      employeeUid == null &&
      date == null;
}

/// Firestore access for `tasks/{taskId}` (PRD §11, §17, §18, §24, §25, §32).
///
/// NOTE ON INDEXES: several of these queries combine equality filters with
/// an orderBy/range on a different field, which requires a Firestore
/// composite index. See firestore.indexes.json and the README for the
/// exact indexes this app needs; Firestore will also print a direct
/// "create index" link in the debug console the first time an
/// unindexed query runs.
class TaskRepository {
  final FirebaseFirestore _db;

  TaskRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.tasks);

  /// PRD §15 — employee's own tasks, real-time.
  Stream<List<TaskModel>> watchMyTasks(String uid) {
    return _col
        .where('assignedTo', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(TaskModel.fromFirestore).toList());
  }

  /// PRD §34 — employee's completed task history.
  Stream<List<TaskModel>> watchMyHistory(String uid) {
    return _col
        .where('assignedTo', isEqualTo: uid)
        .where('status', isEqualTo: TaskStatus.completed.value)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(TaskModel.fromFirestore).toList());
  }

  /// PRD §24, §25 — supervisor real-time monitoring with optional filters.
  /// Applies equality filters via Firestore query where possible; date
  /// (calendar day) filtering on `createdAt` is applied server-side too.
  Stream<List<TaskModel>> watchTasks(TaskFilter filter) {
    Query<Map<String, dynamic>> query = _col;

    if (filter.wardId != null) {
      query = query.where('wardId', isEqualTo: filter.wardId);
    }
    if (filter.status != null) {
      query = query.where('status', isEqualTo: filter.status!.value);
    }
    if (filter.taskType != null) {
      query = query.where('taskType', isEqualTo: filter.taskType!.value);
    }
    if (filter.employeeUid != null) {
      query = query.where('assignedTo', isEqualTo: filter.employeeUid);
    }
    if (filter.date != null) {
      final start = DateTime(filter.date!.year, filter.date!.month, filter.date!.day);
      final end = start.add(const Duration(days: 1));
      query = query
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end));
    }

    query = query.orderBy('createdAt', descending: true);

    return query.snapshots().map(
          (snap) => snap.docs.map(TaskModel.fromFirestore).toList(),
        );
  }

  /// PRD §32 — historical records for a specific date, all tasks.
  Future<List<TaskModel>> getTasksForDate(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      final snap = await _col
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end))
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map(TaskModel.fromFirestore).toList();
    } on FirebaseException catch (e) {
      throw mapFirestoreError(e);
    }
  }

  Future<TaskModel> createTask(TaskModel task) async {
    try {
      final ref = await _col.add(task.toFirestoreCreate());
      final doc = await ref.get();
      return TaskModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw mapFirestoreError(e);
    }
  }

  /// PRD §17 — start task. `currentUid` must match `assignedTo`; the
  /// Firestore security rules also enforce this server-side.
  Future<void> startTask({required String taskId, required String currentUid}) async {
    try {
      final doc = await _col.doc(taskId).get();
      final data = doc.data();
      if (data == null) throw AppException('Task no longer exists.');
      if (data['assignedTo'] != currentUid) {
        throw AppException('You can only start tasks assigned to you.');
      }
      if (data['status'] != TaskStatus.pending.value) {
        throw AppException('This task has already been started.');
      }
      await _col.doc(taskId).update({
        'status': TaskStatus.inProgress.value,
        'startedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw mapFirestoreError(e);
    }
  }

  /// PRD §18 — complete task with optional note/image.
  Future<void> completeTask({
    required String taskId,
    required String currentUid,
    String? completionNote,
    String? imageUrl,
  }) async {
    try {
      final doc = await _col.doc(taskId).get();
      final data = doc.data();
      if (data == null) throw AppException('Task no longer exists.');
      if (data['assignedTo'] != currentUid) {
        throw AppException('You can only complete tasks assigned to you.');
      }
      if (data['status'] != TaskStatus.inProgress.value) {
        throw AppException('Task must be in progress before it can be completed.');
      }
      await _col.doc(taskId).update({
        'status': TaskStatus.completed.value,
        'completedAt': FieldValue.serverTimestamp(),
        if (completionNote != null && completionNote.trim().isNotEmpty)
          'completionNote': completionNote.trim(),
        if (imageUrl != null) 'imageUrl': imageUrl,
      });
    } on FirebaseException catch (e) {
      throw mapFirestoreError(e);
    }
  }

  Future<void> attachImage({required String taskId, required String imageUrl}) async {
    try {
      await _col.doc(taskId).update({'imageUrl': imageUrl});
    } on FirebaseException catch (e) {
      throw mapFirestoreError(e);
    }
  }
}
