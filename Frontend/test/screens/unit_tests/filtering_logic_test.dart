import 'package:flutter_test/flutter_test.dart';
import 'package:pet_connect_app/models/product.dart';

// This function mimics the filtering logic found in _ShopScreenState._onSearchChanged
// to allow for isolated unit testing.
List<Product> filterProducts(List<Product> allProducts, String searchTerm) {
  if (searchTerm.isEmpty) {
    return allProducts;
  }
  return allProducts
      .where(
        (product) => product.name.toLowerCase().contains(
              searchTerm.toLowerCase(),
            ),
      )
      .toList();
}

void main() {
  group('Product Filtering Logic Unit Tests', () {
    // Arrange: A sample list of products to test against.
    final List<Product> sampleProducts = [
      Product(id: '1', name: 'Royal Canin Dog Food', price: '\$50', imageUrl: 'url1'),
      Product(id: '2', name: 'Furry Cat Toy', price: '\$5', imageUrl: 'url2'),
      Product(id: '3', name: 'Premium Dog Leash', price: '\$20', imageUrl: 'url3'),
      Product(id: '4', name: 'Catnip Spray', price: '\$8', imageUrl: 'url4'),
    ];

    test('1. Should return all products when search term is empty', () {
      final result = filterProducts(sampleProducts, '');
      expect(result.length, 4);
    });

    test('2. Should return products matching a simple term (case-insensitive)', () {
      final result = filterProducts(sampleProducts, 'dog');
      expect(result.length, 2);
      // Verify that both returned products actually contain 'dog'
      expect(result.every((p) => p.name.toLowerCase().contains('dog')), isTrue);
    });

    test('3. Should return a single unique product based on a specific term', () {
      final result = filterProducts(sampleProducts, 'leash');
      expect(result.length, 1);
      expect(result.first.id, '3');
    });

    test('4. Should return an empty list if no products match the search term', () {
      final result = filterProducts(sampleProducts, 'fish');
      expect(result, isEmpty);
    });

    test('5. Should handle partial word matches correctly', () {
      final result = filterProducts(sampleProducts, 'canin');
      expect(result.length, 1);
      expect(result.first.name, 'Royal Canin Dog Food');
    });

    test('6. Should handle fully uppercase search terms', () {
      final result = filterProducts(sampleProducts, 'CAT');
      expect(result.length, 2);
      expect(result.every((p) => p.name.toLowerCase().contains('cat')), isTrue);
    });

    test('7. Should return an empty list for untrimmed spaces that break the match', () {
      // 'food ' won't match 'Royal Canin Dog Food' because of the trailing space.
      final result = filterProducts(sampleProducts, 'food ');
      expect(result, isEmpty, reason: "The current logic doesn't trim whitespace, so this is expected.");
    });
  });
}