import 'package:flutter_test/flutter_test.dart';
import 'package:wardclean/core/constants/enums.dart';
import 'package:wardclean/models/task_model.dart';

TaskModel _task({required TaskStatus status, DateTime? dueAt}) {
  return TaskModel(
    taskId: 't1',
    title: 'Test',
    description: '',
    taskType: TaskType.cleaning,
    wardId: 'w1',
    wardName: 'Ward 1',
    roomOrArea: 'Room 1',
    assignedTo: 'u1',
    assignedEmployeeName: 'Employee',
    assignedBy: 's1',
    priority: TaskPriority.medium,
    status: status,
    dueAt: dueAt,
  );
}

void main() {
  group('TaskModel.isOverdue', () {
    test('true for pending task with past due date', () {
      final task = _task(
        status: TaskStatus.pending,
        dueAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(task.isOverdue, isTrue);
    });

    test('false for completed task regardless of due date', () {
      final task = _task(
        status: TaskStatus.completed,
        dueAt: DateTime.now().subtract(const Duration(days: 5)),
      );
      expect(task.isOverdue, isFalse);
    });

    test('false when dueAt is null', () {
      final task = _task(status: TaskStatus.pending, dueAt: null);
      expect(task.isOverdue, isFalse);
    });

    test('false for a future due date', () {
      final task = _task(
        status: TaskStatus.inProgress,
        dueAt: DateTime.now().add(const Duration(hours: 3)),
      );
      expect(task.isOverdue, isFalse);
    });
  });
}
