import 'package:flutter_test/flutter_test.dart';
import 'package:pet_connect_app/models/pet.dart';

void main() {
  group('Pet Model Tests', () {
    test('fromJson should parse valid JSON correctly', () {
      // Arrange
      final Map<String, dynamic> mockJson = {
        'id': '101',
        'name': 'Buddy',
        'animal': 'Dog',
        'breed': 'Golden Retriever',
      };

      // Act
      final result = Pet.fromJson(mockJson);

      // Assert
      expect(result.id, '101');
      expect(result.name, 'Buddy');
      expect(result.animal, 'Dog');
      expect(result.breed, 'Golden Retriever');
    });
  });
}