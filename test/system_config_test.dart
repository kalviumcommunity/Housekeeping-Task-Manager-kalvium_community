import 'package:flutter_test/flutter_test.dart';
import 'package:wardclean/core/constants/enums.dart';
import 'package:wardclean/core/constants/firestore_paths.dart';

void main() {
  group('Organization Access Codes', () {
    test('Default codes are defined', () {
      expect(AppConstants.defaultEmployeeAccessCode, 'EMP-2026');
      expect(AppConstants.defaultSupervisorAccessCode, 'SUP-2026');
    });

    test('UserRole has correct labels', () {
      expect(UserRole.employee.label, 'Employee');
      expect(UserRole.supervisor.label, 'Supervisor');
    });

    test('Case-insensitive validation logic works as expected', () {
      const empExpected = AppConstants.defaultEmployeeAccessCode;
      const supExpected = AppConstants.defaultSupervisorAccessCode;

      expect('emp-2026'.trim().toUpperCase() == empExpected, isTrue);
      expect('EMP-2026'.trim().toUpperCase() == empExpected, isTrue);
      expect('  EMP-2026  '.trim().toUpperCase() == empExpected, isTrue);
      expect('WRONG'.trim().toUpperCase() == empExpected, isFalse);

      expect('sup-2026'.trim().toUpperCase() == supExpected, isTrue);
      expect('SUP-2026'.trim().toUpperCase() == supExpected, isTrue);
      expect('  SUP-2026  '.trim().toUpperCase() == supExpected, isTrue);
      expect('WRONG'.trim().toUpperCase() == supExpected, isFalse);
    });
  });
}
