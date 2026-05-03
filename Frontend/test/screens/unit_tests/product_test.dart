import 'package:flutter_test/flutter_test.dart';
import 'package:pet_connect_app/models/product.dart';

void main() {
  group('Product Model Tests', () {
    
    test('fromMap should parse valid JSON correctly', () {
      // Arrange
      final Map<String, dynamic> mockJson = {
        'id': 'prod_123', // Add the missing 'id' field
        'name': 'Premium Dog Food',
        'price': '\$45.99',
        'image_url': 'https://example.com/dogfood.jpg',
        'product_url': 'https://shop.example.com/dogfood'
      };

      // Act
      final result = Product.fromMap(mockJson);

      // Assert
      expect(result.id, 'prod_123');
      expect(result.name, 'Premium Dog Food');
      expect(result.price, '\$45.99');
      expect(result.imageUrl, 'https://example.com/dogfood.jpg');
      expect(result.productUrl, 'https://shop.example.com/dogfood');
    });
  });
}