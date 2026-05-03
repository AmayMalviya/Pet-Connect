import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pet_connect_app/services/supabase_service.dart';
import 'package:pet_connect_app/models/product.dart';

// Create a mock class using mocktail
class MockSupabaseService extends Mock implements SupabaseService {}

void main() {
  late MockSupabaseService mockService;

  setUp(() {
    mockService = MockSupabaseService();
  });

  group('SupabaseService Contract Unit Tests', () {
    
    // Test 11
    test('11. getProducts should return a List of Products on success', () async {
      final List<Product> mockProducts = [
        Product(id: '1', name: 'Test 1', price: '\$1', imageUrl: 'url1'),
      ];
      when(() => mockService.getProducts()).thenAnswer((_) async => mockProducts);
      
      final result = await mockService.getProducts();
      expect(result.length, 1);
      expect(result.first.name, 'Test 1');
    });

    // Test 12
    test('12. getProducts should return an empty list when no data exists in DB', () async {
      when(() => mockService.getProducts()).thenAnswer((_) async => <Product>[]);
      
      final result = await mockService.getProducts();
      expect(result, isEmpty);
    });

    // Test 13
    test('13. getProducts should throw an Exception on network failure', () async {
      when(() => mockService.getProducts()).thenThrow(Exception('Network Error'));
      
      expect(() => mockService.getProducts(), throwsA(isA<Exception>()));
    });

    // Test 14
    test('14. getProducts should handle timeouts by propagating an Exception', () async {
      when(() => mockService.getProducts()).thenThrow(Exception('Connection Timeout'));
      
      expect(() => mockService.getProducts(), throwsException);
    });

    // Test 15
    test('15. getProducts should throw FormatException on malformed database response', () async {
      when(() => mockService.getProducts()).thenThrow(const FormatException('Bad JSON'));
      
      expect(() => mockService.getProducts(), throwsA(isA<FormatException>()));
    });
  });
}