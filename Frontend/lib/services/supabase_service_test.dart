import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/services/supabase_service.dart';

// 1. Create "Fake" versions of the Supabase classes using mocktail
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}
class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder<dynamic> {}
class MockPostgrestTransformBuilder extends Mock implements PostgrestTransformBuilder<dynamic> {}

void main() {
  group('SupabaseService Tests', () {
    late SupabaseService supabaseService;
    late MockSupabaseClient mockClient;
    late MockSupabaseQueryBuilder mockQueryBuilder;
    late MockPostgrestTransformBuilder mockTransformBuilder;

    setUp(() {
      // Initialize our fakes before every test
      mockClient = MockSupabaseClient();
      mockQueryBuilder = MockSupabaseQueryBuilder();
      mockTransformBuilder = MockPostgrestTransformBuilder();
      
      // Inject the fake client into your service!
      supabaseService = SupabaseService(client: mockClient);
    });

    test('getProducts should return a list of Products on success', () async {
      // Arrange: Set up the dummy data we want the fake database to return
      final mockData = [
        {'id': '1', 'name': 'Bone', 'price': '\$5', 'image_url': 'bone.jpg', 'product_url': 'link1'},
        {'id': '2', 'name': 'Toy', 'price': '\$10', 'image_url': 'toy.jpg', 'product_url': 'link2'},
      ];

      // Tell the fake Supabase client what to do when your app chains the queries:
      // .from('pet_products').select().order('id', ascending: false)
      when(() => mockClient.from('pet_products')).thenReturn(mockQueryBuilder);
      when(() => mockQueryBuilder.select()).thenReturn(mockTransformBuilder as PostgrestFilterBuilder<dynamic>);
      when(() => mockTransformBuilder.order('id', ascending: false)).thenAnswer((_) async => mockData);

      // Act: Call your actual service method
      final products = await supabaseService.getProducts();

      // Assert: Verify that your service correctly turned the fake data into 2 Product objects
      expect(products, isNotNull);
      expect(products.length, 2);
      expect(products[0].name, 'Bone');
      expect(products[1].name, 'Toy');
    });
  });
}