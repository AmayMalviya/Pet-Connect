import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/models/product.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetch products from the 'pet_products' table.
  /// Returns an empty list on error and logs debug information.
  Future<List<Product>> getProducts() async {
    try {
      final dynamic res = await _client
          .from('pet_products')
          .select()
          .order('id', ascending: false);

      print('Supabase getProducts raw response type: ${res.runtimeType}');
      print('Supabase getProducts raw response: $res');

      final List<Map<String, dynamic>> rows = [];

      if (res is List) {
        // already the list of rows
        for (final item in res) {
          if (item is Map) rows.add(Map<String, dynamic>.from(item));
        }
      } else if (res is Map) {
        // Some SDK versions return a Map-like response wrapper
        if (res['error'] != null) {
          print('Supabase error fetching products: ${res['error']}');
          return [];
        }
        final data = res['data'] ?? res['body'] ?? res['result'];
        if (data is List) {
          for (final item in data) {
            if (item is Map) rows.add(Map<String, dynamic>.from(item));
          }
        }
      } else {
        print('Unexpected response shape from Supabase: ${res.runtimeType}');
        return [];
      }

      final products = rows.map((r) => Product.fromJson(r)).toList();
      return products;
    } catch (e) {
      print('Exception in getProducts: $e');
      return [];
    }
  }
}
