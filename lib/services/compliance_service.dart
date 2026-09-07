import '../core/constants/enums.dart';
import '../core/constants/firestore_paths.dart';
import '../models/issue_model.dart';
import '../models/task_model.dart';

/// Result of a daily compliance calculation (PRD §30).
class DailyComplianceSummary {
  final DateTime date;
  final int totalTasks;
  final int completed;
  final int pending;
  final int inProgress;
  final int equipmentChecksCompleted;
  final int equipmentChecksRequired;
  final int issuesReported;
  final int recurringAreas;

  DailyComplianceSummary({
    required this.date,
    required this.totalTasks,
    required this.completed,
    required this.pending,
    required this.inProgress,
    required this.equipmentChecksCompleted,
    required this.equipmentChecksRequired,
    required this.issuesReported,
    required this.recurringAreas,
  });

  /// Rounded percentage, 0 when there are no tasks (avoids divide-by-zero).
  int get completionRate {
    if (totalTasks == 0) return 0;
    return ((completed / totalTasks) * 100).round();
  }
}

/// Pure, Firebase-free business logic. Every method here takes already-
/// fetched model lists and returns a computed result, so it can be unit
/// tested without a Firestore instance (PRD §55).
class ComplianceService {
  ComplianceService._();

  /// PRD §30 — daily compliance summary for a given date's tasks/issues.
  static DailyComplianceSummary buildDailySummary({
    required DateTime date,
    required List<TaskModel> tasksForDay,
    required List<IssueModel> issuesForDay,
    required List<RecurringIssueGroup> recurringGroups,
  }) {
    final completed =
        tasksForDay.where((t) => t.status == TaskStatus.completed).length;
    final pending =
        tasksForDay.where((t) => t.status == TaskStatus.pending).length;
    final inProgress =
        tasksForDay.where((t) => t.status == TaskStatus.inProgress).length;

    final equipmentTasks =
        tasksForDay.where((t) => t.taskType == TaskType.equipmentCheck);
    final equipmentCompleted = equipmentTasks
        .where((t) => t.status == TaskStatus.completed)
        .length;

    return DailyComplianceSummary(
      date: date,
      totalTasks: tasksForDay.length,
      completed: completed,
      pending: pending,
      inProgress: inProgress,
      equipmentChecksCompleted: equipmentCompleted,
      equipmentChecksRequired: equipmentTasks.length,
      issuesReported: issuesForDay.length,
      recurringAreas: recurringGroups.length,
    );
  }

  /// PRD §26 — a task is overdue when not completed/cancelled and past due.
  static bool isOverdue(TaskModel task, {DateTime? now}) {
    final current = now ?? DateTime.now();
    if (task.status == TaskStatus.completed ||
        task.status == TaskStatus.cancelled) {
      return false;
    }
    if (task.dueAt == null) return false;
    return task.dueAt!.isBefore(current);
  }

  static int countOverdue(List<TaskModel> tasks, {DateTime? now}) {
    return tasks.where((t) => isOverdue(t, now: now)).length;
  }

  /// PRD §29 — recurring problem area detection.
  ///
  /// Rule: 3+ issues of the same type, in the same ward + room/area,
  /// within the last [windowDays] days.
  ///
  /// Groups by (wardId, roomOrArea, issueType) over [recentIssues] — the
  /// caller is expected to have already fetched issues within a
  /// reasonably recent window (see IssueRepository.watchRecent).
  static List<RecurringIssueGroup> detectRecurringIssues(
    List<IssueModel> recentIssues, {
    int windowDays = AppConstants.recurringIssueWindowDays,
    int threshold = AppConstants.recurringIssueThreshold,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final cutoff = current.subtract(Duration(days: windowDays));

    final withinWindow = recentIssues.where((issue) {
      if (issue.createdAt == null) return false;
      return issue.createdAt!.isAfter(cutoff) ||
          issue.createdAt!.isAtSameMomentAs(cutoff);
    });

    final grouped = <String, List<IssueModel>>{};
    for (final issue in withinWindow) {
      final key = '${issue.wardId}|${issue.roomOrArea}|${issue.issueType.value}';
      grouped.putIfAbsent(key, () => []).add(issue);
    }

    final result = <RecurringIssueGroup>[];
    grouped.forEach((key, issues) {
      if (issues.length >= threshold) {
        final first = issues.first;
        result.add(RecurringIssueGroup(
          wardId: first.wardId,
          wardName: first.wardName,
          roomOrArea: first.roomOrArea,
          issueType: first.issueType,
          issues: issues,
        ));
      }
    });

    // Most problematic areas first.
    result.sort((a, b) => b.count.compareTo(a.count));
    return result;
  }
}
