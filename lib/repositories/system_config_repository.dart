import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/enums.dart';
import '../core/constants/firestore_paths.dart';

/// Repository for managing system configuration stored in Firestore.
/// Specifically manages organization access codes for employee and supervisor roles
/// to prevent fake account creation.
class SystemConfigRepository {
  final FirebaseFirestore _db;

  SystemConfigRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _accessCodesDoc =>
      _db.collection(FirestorePaths.systemConfig).doc(FirestorePaths.accessCodesDoc);

  /// Retrieves the current official access codes from Firestore.
  /// If the document does not exist yet, initializes it with defaults.
  Future<Map<String, String>> getAccessCodes() async {
    try {
      final snap = await _accessCodesDoc.get();
      if (!snap.exists || snap.data() == null) {
        final defaults = {
          'employeeAccessCode': AppConstants.defaultEmployeeAccessCode,
          'supervisorAccessCode': AppConstants.defaultSupervisorAccessCode,
          'createdAt': FieldValue.serverTimestamp(),
        };
        try {
          await _accessCodesDoc.set(defaults, SetOptions(merge: true));
        } catch (_) {
          // If offline or permission prevents writing, fallback to defaults
        }
        return {
          'employee': AppConstants.defaultEmployeeAccessCode,
          'supervisor': AppConstants.defaultSupervisorAccessCode,
        };
      }

      final data = snap.data()!;
      final empCode = (data['employeeAccessCode'] as String?)?.trim();
      final supCode = (data['supervisorAccessCode'] as String?)?.trim();

      return {
        'employee': (empCode != null && empCode.isNotEmpty)
            ? empCode
            : AppConstants.defaultEmployeeAccessCode,
        'supervisor': (supCode != null && supCode.isNotEmpty)
            ? supCode
            : AppConstants.defaultSupervisorAccessCode,
      };
    } catch (_) {
      return {
        'employee': AppConstants.defaultEmployeeAccessCode,
        'supervisor': AppConstants.defaultSupervisorAccessCode,
      };
    }
  }

  /// Validates whether the given [enteredCode] matches the expected code for [role].
  /// Matches case-insensitively.
  Future<bool> validateAccessCode({
    required UserRole role,
    required String enteredCode,
  }) async {
    final codes = await getAccessCodes();
    final expected = role == UserRole.supervisor
        ? codes['supervisor']
        : codes['employee'];

    if (expected == null || expected.isEmpty) return false;
    return enteredCode.trim().toUpperCase() == expected.trim().toUpperCase();
  }

  /// Manually set or update access codes (e.g. by supervisor or admin).
  Future<void> updateAccessCodes({
    String? employeeCode,
    String? supervisorCode,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (employeeCode != null && employeeCode.trim().isNotEmpty) {
      updates['employeeAccessCode'] = employeeCode.trim().toUpperCase();
    }
    if (supervisorCode != null && supervisorCode.trim().isNotEmpty) {
      updates['supervisorAccessCode'] = supervisorCode.trim().toUpperCase();
    }
    await _accessCodesDoc.set(updates, SetOptions(merge: true));
  }
}
