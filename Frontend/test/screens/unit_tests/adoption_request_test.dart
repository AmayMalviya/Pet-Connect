import 'package:flutter_test/flutter_test.dart';
import 'package:pet_connect_app/models/adoption_request.dart';

void main() {
  group('AdoptionRequest Model Tests', () {
    
    test('fromJson should properly parse a valid JSON map', () {
      // 1. Arrange: Create a fake JSON response similar to what Supabase returns
      final Map<String, dynamic> mockJson = {
        'id': 1,
        'petId': 101,
        'requesterId': 'user-123',
        'shelterOwnerId': 'shelter-456',
        'status': 'Pending',
        'pet': {
          'id': 101,
          'name': 'Buddy',
          'animal': 'Dog',
          'breed': 'Golden Retriever',
        },
        'requester': {
          'uid': 'user-123',
          'email': 'adopter@example.com',
          'displayName': 'John Adopter',
        }
      };

      // 2. Act: Pass the fake JSON into your model's fromJson factory
      final result = AdoptionRequest.fromJson(mockJson);

      // 3. Assert: Verify the data was parsed into the object correctly
      expect(result.id, 1);
      expect(result.petId, 101);
      expect(result.requesterId, 'user-123');
      expect(result.shelterOwnerId, 'shelter-456');
      expect(result.status, 'Pending');
      
      // Verify nested objects are parsed correctly
      expect(result.pet, isNotNull);
      expect(result.pet.name, 'Buddy');
      
      expect(result.requester, isNotNull);
      expect(result.requester.displayName, 'John Adopter');
    });
  });
}