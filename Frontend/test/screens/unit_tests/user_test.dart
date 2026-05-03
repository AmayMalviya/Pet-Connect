import 'package:flutter_test/flutter_test.dart';
import 'package:pet_connect_app/models/user.dart';

void main() {
  group('User Model Tests', () {
    test('fromJson should parse valid JSON correctly', () {
      // Arrange
      final Map<String, dynamic> mockJson = {
        'uid': 'user-123',
        'email': 'adopter@example.com',
        'displayName': 'John Adopter',
      };

      // Act
      final result = User.fromJson(mockJson);

      // Assert
      expect(result.uid, 'user-123');
      expect(result.email, 'adopter@example.com');
      expect(result.displayName, 'John Adopter');
    });
  });
}