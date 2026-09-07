import 'package:flutter_test/flutter_test.dart';
import 'package:wardclean/core/constants/enums.dart';

void main() {
  group('Enum round-tripping', () {
    test('UserRole', () {
      for (final r in UserRole.values) {
        expect(UserRole.fromValue(r.value), r);
      }
      expect(UserRole.fromValue('nonsense'), UserRole.employee); // safe default
      expect(UserRole.fromValue(null), UserRole.employee);
    });

    test('TaskStatus', () {
      for (final s in TaskStatus.values) {
        expect(TaskStatus.fromValue(s.value), s);
      }
      expect(TaskStatus.fromValue('bogus'), TaskStatus.pending);
    });

    test('TaskPriority', () {
      for (final p in TaskPriority.values) {
        expect(TaskPriority.fromValue(p.value), p);
      }
      expect(TaskPriority.fromValue('bogus'), TaskPriority.medium);
    });

    test('TaskType', () {
      for (final t in TaskType.values) {
        expect(TaskType.fromValue(t.value), t);
      }
    });

    test('IssueStatus', () {
      for (final s in IssueStatus.values) {
        expect(IssueStatus.fromValue(s.value), s);
      }
      expect(IssueStatus.fromValue('bogus'), IssueStatus.open);
    });

    test('IssueType', () {
      for (final t in IssueType.values) {
        expect(IssueType.fromValue(t.value), t);
      }
      expect(IssueType.fromValue('bogus'), IssueType.other);
    });
  });
}
