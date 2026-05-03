import 'package:flutter_test/flutter_test.dart';

// Mimics validation logic that would be used in a form (e.g., LoginScreen)
String? validateEmail(String? email) {
  if (email == null || email.trim().isEmpty) return 'Email cannot be empty';
  final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(email.trim())) return 'Enter a valid email address';
  return null;
}

String? validatePassword(String? password) {
  if (password == null || password.isEmpty) return 'Password cannot be empty';
  if (password.length < 6) return 'Password must be at least 6 characters';
  return null;
}

void main() {
  group('Form Validation Logic Unit Tests', () {
    // --- Email Validation Tests ---
    test('1. Should return error if email is empty or null', () {
      expect(validateEmail(''), 'Email cannot be empty');
      expect(validateEmail(null), 'Email cannot be empty');
      expect(validateEmail('   '), 'Email cannot be empty');
    });

    test('2. Should return error for invalid email formats', () {
      expect(validateEmail('plainaddress'), 'Enter a valid email address');
      expect(validateEmail('@missingusername.com'), 'Enter a valid email address');
      expect(validateEmail('user@.com'), 'Enter a valid email address');
    });

    test('3. Should return null (success) for valid emails', () {
      expect(validateEmail('test@example.com'), isNull);
      expect(validateEmail('user.name+tag@domain.co.uk'), isNull);
    });

    // --- Password Validation Tests ---
    test('4. Should return error if password is empty or null', () {
      expect(validatePassword(''), 'Password cannot be empty');
      expect(validatePassword(null), 'Password cannot be empty');
    });

    test('5. Should return error if password is too short', () {
      expect(validatePassword('12345'), 'Password must be at least 6 characters');
      expect(validatePassword('123456'), isNull); // 6 is valid
    });
  });
}
