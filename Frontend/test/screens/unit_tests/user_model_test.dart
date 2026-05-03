import 'package:flutter_test/flutter_test.dart';
import 'package:pet_connect_app/models/user.dart';

void main() {
  group('User Model Unit Tests', () {
    final Map<String, dynamic> validUserJson = {
      'uid': 'user_123',
      'displayName': 'John Doe',
      'email': 'john@example.com',
      'photoUrl': 'https://example.com/avatar.png',
    };

    test('1. Should correctly instantiate a User with all fields', () {
      final user = User(
        uid: '1',
        displayName: 'Alice',
        email: 'alice@test.com',
        photoUrl: 'url',
      );
      expect(user.displayName, 'Alice');
      expect(user.email, 'alice@test.com');
    });

    test('2. fromJson should parse valid JSON correctly', () {
      final user = User.fromJson(validUserJson);
      expect(user.uid, 'user_123');
      expect(user.displayName, 'John Doe');
      expect(user.photoUrl, 'https://example.com/avatar.png');
    });

    test('3. fromJson should handle missing optional photoUrl', () {
      final jsonWithoutUrl = Map<String, dynamic>.from(validUserJson)..remove('photoUrl');
      final user = User.fromJson(jsonWithoutUrl);
      expect(user.photoUrl, isNull);
    });

    test('4. toJson should serialize correctly', () {
      final user = User.fromJson(validUserJson);
      final json = user.toJson();
      expect(json['email'], 'john@example.com');
      expect(json['uid'], 'user_123');
    });

    test('5. fromJson should throw error if required email is missing', () {
      final invalidJson = Map<String, dynamic>.from(validUserJson)..remove('email');
      expect(() => User.fromJson(invalidJson), throwsA(isA<TypeError>()));
    });
  });
}