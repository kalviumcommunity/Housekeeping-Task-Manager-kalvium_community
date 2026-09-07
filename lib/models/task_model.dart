import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/enums.dart';

/// Maps to `tasks/{taskId}` (PRD §11).
class TaskModel {
  final String taskId;
  final String title;
  final String description;
  final TaskType taskType;
  final String wardId;
  final String wardName;
  final String roomOrArea;
  final String assignedTo; // employee UID
  final String assignedEmployeeName;
  final String assignedBy; // supervisor UID
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? createdAt;
  final DateTime? dueAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? completionNote;
  final String? imageUrl;

  TaskModel({
    required this.taskId,
    required this.title,
    required this.description,
    required this.taskType,
    required this.wardId,
    required this.wardName,
    required this.roomOrArea,
    required this.assignedTo,
    required this.assignedEmployeeName,
    required this.assignedBy,
    required this.priority,
    required this.status,
    this.createdAt,
    this.dueAt,
    this.startedAt,
    this.completedAt,
    this.completionNote,
    this.imageUrl,
  });

  /// PRD §26 — overdue means not completed/cancelled and past due date.
  bool get isOverdue {
    if (status == TaskStatus.completed || status == TaskStatus.cancelled) {
      return false;
    }
    if (dueAt == null) return false;
    return dueAt!.isBefore(DateTime.now());
  }

  factory TaskModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return TaskModel(
      taskId: doc.id,
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      taskType: TaskType.fromValue(data['taskType'] as String?),
      wardId: (data['wardId'] as String?) ?? '',
      wardName: (data['wardName'] as String?) ?? '',
      roomOrArea: (data['roomOrArea'] as String?) ?? '',
      assignedTo: (data['assignedTo'] as String?) ?? '',
      assignedEmployeeName: (data['assignedEmployeeName'] as String?) ?? '',
      assignedBy: (data['assignedBy'] as String?) ?? '',
      priority: TaskPriority.fromValue(data['priority'] as String?),
      status: TaskStatus.fromValue(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      dueAt: (data['dueAt'] as Timestamp?)?.toDate(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      completionNote: data['completionNote'] as String?,
      imageUrl: data['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestoreCreate() {
    return {
      'title': title,
      'description': description,
      'taskType': taskType.value,
      'wardId': wardId,
      'wardName': wardName,
      'roomOrArea': roomOrArea,
      'assignedTo': assignedTo,
      'assignedEmployeeName': assignedEmployeeName,
      'assignedBy': assignedBy,
      'priority': priority.value,
      'status': TaskStatus.pending.value,
      'createdAt': FieldValue.serverTimestamp(),
      'dueAt': dueAt != null ? Timestamp.fromDate(dueAt!) : null,
      'startedAt': null,
      'completedAt': null,
      'completionNote': null,
      'imageUrl': null,
    };
  }
}
