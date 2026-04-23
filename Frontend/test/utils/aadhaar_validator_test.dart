import 'package:flutter_test/flutter_test.dart';
import 'package:pet_connect_app/utils/aadhaar_validator.dart';

void main() {
  group('AadhaarValidator.validate', () {
    test('should return true for valid Aadhaar numbers', () {
      // Examples from online Aadhaar validators or known valid patterns
      expect(AadhaarValidator.validate('361174549552'), isTrue);
      expect(AadhaarValidator.validate('3611 7454 9552'), isTrue);
      expect(AadhaarValidator.validate('3611-7454-9552'), isTrue);
    });

    test('should return false for invalid Aadhaar numbers', () {
      expect(AadhaarValidator.validate('123456789012'), isFalse);
      expect(AadhaarValidator.validate('000000000000'), isFalse);
      expect(AadhaarValidator.validate('361174549555'), isFalse); // Last digit changed
    });

    test('should return false for incorrect lengths', () {
      expect(AadhaarValidator.validate('12345678901'), isFalse);
      expect(AadhaarValidator.validate('1234567890123'), isFalse);
    });

    test('should return false for non-numeric input', () {
      expect(AadhaarValidator.validate('12345678901A'), isFalse);
    });
  });

  group('AadhaarValidator.mask', () {
    test('should mask Aadhaar number correctly', () {
      expect(AadhaarValidator.mask('361174549554'), 'XXXX-XXXX-9554');
      expect(AadhaarValidator.mask('3611 7454 9554'), 'XXXX-XXXX-9554');
    });
  });
}
