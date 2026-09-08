/// Central enums for WardClean.
///
/// Firestore stores these as plain lowercase strings (see PRD §6, §11, §12),
/// so every enum here round-trips through `.value` / `fromValue`.
library;

enum UserRole {
  employee('employee', 'Employee'),
  supervisor('supervisor', 'Supervisor');

  final String value;
  final String label;
  const UserRole(this.value, this.label);

  static UserRole fromValue(String? value) {
    return UserRole.values.firstWhere(
      (r) => r.value == value,
      orElse: () => UserRole.employee,
    );
  }
}

enum TaskStatus {
  pending('pending'),
  inProgress('in_progress'),
  completed('completed'),
  cancelled('cancelled');

  final String value;
  const TaskStatus(this.value);

  static TaskStatus fromValue(String? value) {
    return TaskStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => TaskStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }
}

enum TaskPriority {
  low('low'),
  medium('medium'),
  high('high');

  final String value;
  const TaskPriority(this.value);

  static TaskPriority fromValue(String? value) {
    return TaskPriority.values.firstWhere(
      (p) => p.value == value,
      orElse: () => TaskPriority.medium,
    );
  }

  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }
}

enum TaskType {
  cleaning('Cleaning'),
  equipmentCheck('Equipment Check'),
  wasteDisposal('Waste Disposal'),
  linenChange('Linen Change'),
  disinfection('Disinfection');

  final String value;
  const TaskType(this.value);

  static TaskType fromValue(String? value) {
    return TaskType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => TaskType.cleaning,
    );
  }
}

enum IssueStatus {
  open('open'),
  resolved('resolved');

  final String value;
  const IssueStatus(this.value);

  static IssueStatus fromValue(String? value) {
    return IssueStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => IssueStatus.open,
    );
  }

  String get label => this == IssueStatus.open ? 'Open' : 'Resolved';
}

enum IssueType {
  cleaningQuality('Cleaning Quality'),
  missedCleaning('Missed Cleaning'),
  equipmentDamage('Equipment Damage'),
  equipmentUnavailable('Equipment Unavailable'),
  supplyShortage('Supply Shortage'),
  wasteDisposal('Waste Disposal'),
  other('Other');

  final String value;
  const IssueType(this.value);

  static IssueType fromValue(String? value) {
    return IssueType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => IssueType.other,
    );
  }
}
