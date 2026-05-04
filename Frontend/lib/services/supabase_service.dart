import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/models/product.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetch products from the 'pet_products' table.
  /// Returns an empty list on error and logs debug information.
  Future<List<Product>> getProducts({int limit = 20, int offset = 0}) async {
    try {
      final response = await _client
          .from('pet_products')
          .select()
          .order('id', ascending: false)
          .limit(limit)
          .range(offset, offset + limit - 1);

      if (response.isNotEmpty) {
        return response.map((item) => Product.fromMap(item)).toList();
      }
    } catch (e) {
      print('Exception in getProducts: $e');
    }
    
    // Fallback mock products if database is empty or fails
    return _getMockProducts();
  }

  List<Product> _getMockProducts() {
    return [
      Product(
        id: '1',
        name: 'Premium Adult Dog Food',
        price: '45.99',
        imageUrl: 'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=500&q=80',
        category: 'Food',
        petType: 'dog',
        species: ['dog'],
        rating: 4.8,
      ),
      Product(
        id: '2',
        name: 'Interactive Cat Laser Toy',
        price: '15.99',
        imageUrl: 'https://images.unsplash.com/photo-1545249390-6bdfa286032f?w=500&q=80',
        category: 'Toys',
        petType: 'cat',
        species: ['cat'],
        rating: 4.5,
      ),
      Product(
        id: '3',
        name: 'Orthopedic Dog Bed',
        price: '65.00',
        imageUrl: 'https://images.unsplash.com/photo-1541599540903-216a46ca1dc0?w=500&q=80',
        category: 'Beds',
        petType: 'dog',
        species: ['dog'],
        rating: 4.9,
      ),
      Product(
        id: '4',
        name: 'Natural Cat Grooming Brush',
        price: '12.50',
        imageUrl: 'https://images.unsplash.com/photo-1513245543132-31f507417b26?w=500&q=80',
        category: 'Grooming',
        petType: 'cat',
        species: ['cat'],
        rating: 4.6,
      ),
      Product(
        id: '5',
        name: 'Heavy Duty Dog Leash',
        price: '22.99',
        imageUrl: 'https://images.unsplash.com/photo-1605897472359-85e4b94d685d?w=500&q=80',
        category: 'Accessories',
        petType: 'dog',
        species: ['dog'],
        rating: 4.7,
      ),
      Product(
        id: '6',
        name: 'Bird Seed Mix',
        price: '18.50',
        imageUrl: 'https://images.unsplash.com/photo-1552728089-571ebf4eb70c?w=500&q=80',
        category: 'Food',
        petType: 'bird',
        species: ['bird'],
        rating: 4.4,
      ),
      Product(
        id: '7',
        name: 'Cat Scratching Post',
        price: '34.99',
        imageUrl: 'https://images.unsplash.com/photo-1623387641168-d9803ddd3f35?w=500&q=80',
        category: 'Toys',
        petType: 'cat',
        species: ['cat'],
        rating: 4.8,
      ),
      Product(
        id: '8',
        name: 'Dog Chew Bone',
        price: '8.99',
        imageUrl: 'https://images.unsplash.com/photo-1583337130417-3346a1be7dee?w=500&q=80',
        category: 'Toys',
        petType: 'dog',
        species: ['dog'],
        rating: 4.3,
      ),
      Product(
        id: '9',
        name: 'Cozy Cat Cave Bed',
        price: '28.50',
        imageUrl: 'https://images.unsplash.com/photo-1517849845537-4d257902454a?w=500&q=80',
        category: 'Beds',
        petType: 'cat',
        species: ['cat'],
        rating: 4.9,
      ),
      Product(
        id: '10',
        name: 'Dog Grooming Shampoo',
        price: '14.99',
        imageUrl: 'https://images.unsplash.com/photo-1516734212186-a967f81ad0d7?w=500&q=80',
        category: 'Grooming',
        petType: 'dog',
        species: ['dog'],
        rating: 4.6,
      ),
    ];
  }

  /// Track product click for analytics
  Future<void> trackProductClick(String productId, String userId) async {
    try {
      await _client.from('product_clicks').insert({
        'product_id': productId,
        'user_id': userId,
        'clicked_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error tracking product click: $e');
    }
  }
}
