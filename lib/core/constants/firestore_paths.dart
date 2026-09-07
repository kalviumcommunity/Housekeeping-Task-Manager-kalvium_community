/// Firestore collection names, centralized so paths are never hand-typed
/// in multiple places (and so security rules / code stay in sync).
class FirestorePaths {
  FirestorePaths._();

  static const String users = 'users';
  static const String wards = 'wards';
  static const String tasks = 'tasks';
  static const String issues = 'issues';
}

/// Firebase Storage path helpers (PRD §20).
class StoragePaths {
  StoragePaths._();

  static String taskImage(String taskId, String fileName) =>
      'task_images/$taskId/$fileName';

  static String issueImage(String issueId, String fileName) =>
      'issue_images/$issueId/$fileName';
}

/// Business rule constants (kept in one place so they're easy to audit).
class AppConstants {
  AppConstants._();

  /// PRD §29 — recurring issue detection window.
  static const int recurringIssueWindowDays = 7;

  /// PRD §29 — minimum matching issues to flag a recurring problem area.
  static const int recurringIssueThreshold = 3;

  /// PRD §51 — max image size before we warn/compress (5 MB).
  static const int maxImageBytes = 5 * 1024 * 1024;
}
