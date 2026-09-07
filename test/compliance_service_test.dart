import 'package:flutter_test/flutter_test.dart';
import 'package:wardclean/core/constants/enums.dart';
import 'package:wardclean/models/issue_model.dart';
import 'package:wardclean/models/task_model.dart';
import 'package:wardclean/services/compliance_service.dart';

TaskModel _task({
  required TaskStatus status,
  DateTime? dueAt,
  TaskType type = TaskType.cleaning,
}) {
  return TaskModel(
    taskId: 't1',
    title: 'Test Task',
    description: '',
    taskType: type,
    wardId: 'ward_01',
    wardName: 'Ward 1',
    roomOrArea: 'Room 1',
    assignedTo: 'uid1',
    assignedEmployeeName: 'Employee',
    assignedBy: 'sup1',
    priority: TaskPriority.medium,
    status: status,
    dueAt: dueAt,
  );
}

IssueModel _issue({
  required DateTime createdAt,
  String wardId = 'ward_02',
  String room = 'Room 5',
  IssueType type = IssueType.cleaningQuality,
}) {
  return IssueModel(
    issueId: 'i-${createdAt.microsecondsSinceEpoch}',
    wardId: wardId,
    wardName: 'Ward 2',
    roomOrArea: room,
    issueType: type,
    description: 'desc',
    reportedBy: 'uid1',
    reportedByName: 'Employee',
    priority: TaskPriority.medium,
    status: IssueStatus.open,
    createdAt: createdAt,
  );
}

void main() {
  group('ComplianceService.isOverdue', () {
    final now = DateTime(2026, 8, 15, 12, 0);

    test('pending task past due date is overdue', () {
      final task = _task(status: TaskStatus.pending, dueAt: now.subtract(const Duration(hours: 1)));
      expect(ComplianceService.isOverdue(task, now: now), isTrue);
    });

    test('in-progress task past due date is overdue', () {
      final task =
          _task(status: TaskStatus.inProgress, dueAt: now.subtract(const Duration(minutes: 1)));
      expect(ComplianceService.isOverdue(task, now: now), isTrue);
    });

    test('completed task past due date is NOT overdue', () {
      final task = _task(status: TaskStatus.completed, dueAt: now.subtract(const Duration(days: 1)));
      expect(ComplianceService.isOverdue(task, now: now), isFalse);
    });

    test('cancelled task past due date is NOT overdue', () {
      final task = _task(status: TaskStatus.cancelled, dueAt: now.subtract(const Duration(days: 1)));
      expect(ComplianceService.isOverdue(task, now: now), isFalse);
    });

    test('task with no due date is never overdue', () {
      final task = _task(status: TaskStatus.pending, dueAt: null);
      expect(ComplianceService.isOverdue(task, now: now), isFalse);
    });

    test('task due in the future is not overdue', () {
      final task = _task(status: TaskStatus.pending, dueAt: now.add(const Duration(hours: 1)));
      expect(ComplianceService.isOverdue(task, now: now), isFalse);
    });
  });

  group('ComplianceService.countOverdue', () {
    test('counts only overdue, active tasks', () {
      final now = DateTime(2026, 8, 15, 12, 0);
      final tasks = [
        _task(status: TaskStatus.pending, dueAt: now.subtract(const Duration(hours: 1))), // overdue
        _task(status: TaskStatus.inProgress, dueAt: now.subtract(const Duration(hours: 2))), // overdue
        _task(status: TaskStatus.completed, dueAt: now.subtract(const Duration(hours: 3))), // not
        _task(status: TaskStatus.pending, dueAt: now.add(const Duration(hours: 1))), // not
      ];
      expect(ComplianceService.countOverdue(tasks, now: now), 2);
    });
  });

  group('ComplianceService.detectRecurringIssues', () {
    final now = DateTime(2026, 8, 15, 12, 0);

    test('flags a group with 3+ matching issues within the window', () {
      final issues = [
        _issue(createdAt: now.subtract(const Duration(days: 1))),
        _issue(createdAt: now.subtract(const Duration(days: 3))),
        _issue(createdAt: now.subtract(const Duration(days: 5))),
      ];
      final groups = ComplianceService.detectRecurringIssues(issues, now: now);
      expect(groups.length, 1);
      expect(groups.first.count, 3);
      expect(groups.first.roomOrArea, 'Room 5');
    });

    test('does NOT flag a group with only 2 matching issues', () {
      final issues = [
        _issue(createdAt: now.subtract(const Duration(days: 1))),
        _issue(createdAt: now.subtract(const Duration(days: 3))),
      ];
      final groups = ComplianceService.detectRecurringIssues(issues, now: now);
      expect(groups, isEmpty);
    });

    test('issues outside the 7-day window are excluded', () {
      final issues = [
        _issue(createdAt: now.subtract(const Duration(days: 1))),
        _issue(createdAt: now.subtract(const Duration(days: 2))),
        _issue(createdAt: now.subtract(const Duration(days: 10))), // outside window
      ];
      final groups = ComplianceService.detectRecurringIssues(issues, now: now);
      expect(groups, isEmpty);
    });

    test('different issue types in the same room do not combine', () {
      final issues = [
        _issue(createdAt: now.subtract(const Duration(days: 1)), type: IssueType.cleaningQuality),
        _issue(createdAt: now.subtract(const Duration(days: 2)), type: IssueType.equipmentDamage),
        _issue(createdAt: now.subtract(const Duration(days: 3)), type: IssueType.supplyShortage),
      ];
      final groups = ComplianceService.detectRecurringIssues(issues, now: now);
      expect(groups, isEmpty);
    });

    test('different wards/rooms do not combine even with the same type', () {
      final issues = [
        _issue(createdAt: now.subtract(const Duration(days: 1)), wardId: 'ward_01', room: 'Room 1'),
        _issue(createdAt: now.subtract(const Duration(days: 2)), wardId: 'ward_02', room: 'Room 2'),
        _issue(createdAt: now.subtract(const Duration(days: 3)), wardId: 'ward_03', room: 'Room 3'),
      ];
      final groups = ComplianceService.detectRecurringIssues(issues, now: now);
      expect(groups, isEmpty);
    });

    test('respects a custom threshold and window', () {
      final issues = [
        _issue(createdAt: now.subtract(const Duration(days: 1))),
        _issue(createdAt: now.subtract(const Duration(days: 2))),
      ];
      final groups = ComplianceService.detectRecurringIssues(
        issues,
        now: now,
        threshold: 2,
        windowDays: 3,
      );
      expect(groups.length, 1);
    });
  });

  group('ComplianceService.buildDailySummary', () {
    test('computes completion rate and equipment check counts correctly', () {
      final tasks = [
        _task(status: TaskStatus.completed),
        _task(status: TaskStatus.completed),
        _task(status: TaskStatus.pending),
        _task(status: TaskStatus.inProgress),
        _task(status: TaskStatus.completed, type: TaskType.equipmentCheck),
        _task(status: TaskStatus.pending, type: TaskType.equipmentCheck),
      ];

      final summary = ComplianceService.buildDailySummary(
        date: DateTime(2026, 8, 17),
        tasksForDay: tasks,
        issuesForDay: [],
        recurringGroups: [],
      );

      expect(summary.totalTasks, 6);
      expect(summary.completed, 3);
      expect(summary.pending, 2);
      expect(summary.inProgress, 1);
      expect(summary.equipmentChecksRequired, 2);
      expect(summary.equipmentChecksCompleted, 1);
      expect(summary.completionRate, 50); // 3/6 = 50%
    });

    test('completion rate is 0 when there are no tasks (no divide-by-zero)', () {
      final summary = ComplianceService.buildDailySummary(
        date: DateTime(2026, 8, 17),
        tasksForDay: [],
        issuesForDay: [],
        recurringGroups: [],
      );
      expect(summary.completionRate, 0);
    });
  });
}
