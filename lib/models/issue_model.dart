import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/enums.dart';

/// Maps to `issues/{issueId}` (PRD §12).
class IssueModel {
  final String issueId;
  final String wardId;
  final String wardName;
  final String roomOrArea;
  final IssueType issueType;
  final String description;
  final String reportedBy; // uid
  final String reportedByName;
  final String? relatedTaskId;
  final TaskPriority priority;
  final IssueStatus status;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  IssueModel({
    required this.issueId,
    required this.wardId,
    required this.wardName,
    required this.roomOrArea,
    required this.issueType,
    required this.description,
    required this.reportedBy,
    required this.reportedByName,
    this.relatedTaskId,
    required this.priority,
    required this.status,
    this.imageUrl,
    this.createdAt,
    this.resolvedAt,
  });

  factory IssueModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return IssueModel(
      issueId: doc.id,
      wardId: (data['wardId'] as String?) ?? '',
      wardName: (data['wardName'] as String?) ?? '',
      roomOrArea: (data['roomOrArea'] as String?) ?? '',
      issueType: IssueType.fromValue(data['issueType'] as String?),
      description: (data['description'] as String?) ?? '',
      reportedBy: (data['reportedBy'] as String?) ?? '',
      reportedByName: (data['reportedByName'] as String?) ?? '',
      relatedTaskId: data['relatedTaskId'] as String?,
      priority: TaskPriority.fromValue(data['priority'] as String?),
      status: IssueStatus.fromValue(data['status'] as String?),
      imageUrl: data['imageUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestoreCreate() {
    return {
      'wardId': wardId,
      'wardName': wardName,
      'roomOrArea': roomOrArea,
      'issueType': issueType.value,
      'description': description,
      'reportedBy': reportedBy,
      'reportedByName': reportedByName,
      'relatedTaskId': relatedTaskId,
      'priority': priority.value,
      'status': IssueStatus.open.value,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'resolvedAt': null,
    };
  }
}

/// PRD §29 — a computed (non-Firestore) grouping used to flag a
/// recurring problem area. Built client-side from real IssueModel records.
class RecurringIssueGroup {
  final String wardId;
  final String wardName;
  final String roomOrArea;
  final IssueType issueType;
  final List<IssueModel> issues;

  RecurringIssueGroup({
    required this.wardId,
    required this.wardName,
    required this.roomOrArea,
    required this.issueType,
    required this.issues,
  });

  int get count => issues.length;
}
