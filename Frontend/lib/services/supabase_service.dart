import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/models/product.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetch products from the 'pet_products' table.
  /// Returns an empty list on error and logs debug information.
  Future<List<Product>> getProducts() async {
    try {
      final response = await _client
          .from('pet_products')
          .select()
          .order('id', ascending: false);

      if (response.isEmpty) {
        print('No products found from Supabase.');
        return [];
      }

      final products =
          response.map((item) => Product.fromJson(item)).toList();
      return products;
    } catch (e) {
      print('Exception in getProducts: $e');
      return [];
    }
  }
}
