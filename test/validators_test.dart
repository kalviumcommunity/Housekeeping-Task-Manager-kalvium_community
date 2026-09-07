import 'package:flutter_test/flutter_test.dart';
import 'package:wardclean/core/validators/validators.dart';

void main() {
  group('Validators.required', () {
    test('null or empty returns error', () {
      expect(Validators.required(null), isNotNull);
      expect(Validators.required(''), isNotNull);
      expect(Validators.required('   '), isNotNull);
    });

    test('non-empty returns null', () {
      expect(Validators.required('Room 5'), isNull);
    });
  });

  group('Validators.email', () {
    test('rejects invalid emails', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('missing@domain'), isNotNull);
      expect(Validators.email('@nodomain.com'), isNotNull);
    });

    test('accepts valid emails', () {
      expect(Validators.email('a@b.com'), isNull);
      expect(Validators.email('employee.one@wardclean.demo'), isNull);
    });
  });

  group('Validators.password', () {
    test('rejects short passwords', () {
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password(''), isNotNull);
    });

    test('accepts 6+ character passwords', () {
      expect(Validators.password('123456'), isNull);
    });
  });

  group('Validators.matchPassword', () {
    test('rejects mismatched passwords', () {
      expect(Validators.matchPassword('abc123', 'abc124'), isNotNull);
    });

    test('accepts matching passwords', () {
      expect(Validators.matchPassword('abc123', 'abc123'), isNull);
    });
  });
}
