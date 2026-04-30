import 'package:flutter_test/flutter_test.dart';
import 'package:pet_connect_app/models/product.dart';

void main() {
  group('Product Model Deep Dive Tests', () {
    
    // Test 1: Perfect Data
    test('fromMap parses fully populated JSON correctly', () {
      final Map<String, dynamic> mockJson = {
        'id': 'prod_123',
        'name': 'Premium Dog Food',
        'price': '\$45.99',
        'image_url': 'https://example.com/dogfood.jpg',
        'product_url': 'https://shop.example.com/dogfood',
        'rating': 4.5,
        'category': 'food',
        'pet_type': 'dog',
        'tags': ['premium', 'beef']
      };

      final result = Product.fromMap(mockJson);

      expect(result.id, 'prod_123');
      expect(result.rating, 4.5);
      expect(result.category, 'food');
      expect(result.petType, 'dog');
      expect(result.tags, ['premium', 'beef']);
    });

    // Test 2: Missing Optional Data
    test('fromMap handles missing optional fields gracefully', () {
      final Map<String, dynamic> mockJson = {
        'id': 'prod_456',
        'name': 'Basic Cat Toy',
        'price': '\$5.00',
        // Missing imageUrl, productUrl, rating, etc.
      };

      final result = Product.fromMap(mockJson);

      expect(result.id, 'prod_456');
      expect(result.name, 'Basic Cat Toy');
      expect(result.imageUrl, ''); // Should default to empty string
      expect(result.rating, isNull);
      expect(result.category, isNull);
    });

    // Test 3: Serialization
    test('toJson serializes Product object back to Map correctly', () {
      final product = Product(
        id: 'prod_789',
        name: 'Bird Cage',
        price: '\$120.00',
        imageUrl: 'cage.png',
        petType: 'bird',
      );

      final json = product.toJson();

      expect(json['id'], 'prod_789');
      expect(json['name'], 'Bird Cage');
      expect(json['pet_type'], 'bird');
      expect(json['rating'], isNull);
    });

    // Test 4: Static Methods
    test('getPetCategories returns a non-empty map of categories', () {
      final categories = Product.getPetCategories();
      
      expect(categories.isNotEmpty, true);
      expect(categories.containsKey('dog'), true);
      expect(categories.containsKey('cat'), true);
    });

    // Test 5: Category Filtering (Success)
    test('getCategoriesForPet returns correct list for dog', () {
      final dogCategories = Product.getCategoriesForPet('dog');
      
      expect(dogCategories.isNotEmpty, true);
      expect(dogCategories.contains('food'), true);
      expect(dogCategories.contains('leash'), true);
    });

    // Test 6: Category Filtering (Failure/Edge Case)
    test('getCategoriesForPet returns empty list for unknown animal', () {
      final dragonCategories = Product.getCategoriesForPet('dragon');
      
      expect(dragonCategories.isEmpty, true);
      expect(dragonCategories, []);
    });
  });
}