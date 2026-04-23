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

      if (response.isEmpty) {
        print('No products found from Supabase.');
        return [];
      }

      final products = response.map((item) => Product.fromMap(item)).toList();
      return products;
    } catch (e) {
      print('Exception in getProducts: $e');
      return [];
    }
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
