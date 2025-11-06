import 'package:pet_connect_app/models/recommended_product.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecommendationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<RecommendedProduct>> getRecommendedProducts(String petId) async {
    try {
      print('Fetching recommendations for petId: $petId');
      final response = await _supabase
          .from('breed_recommendations')
          .select()
          .eq('pet_id', petId)
          .order('match_score', ascending: false)
          .order('price', ascending: true)
          .limit(30);

      print('Supabase response: $response');

      if (response == null) {
        print('No recommended products found.');
        return [];
      }

      final productList = (response as List).map((json) => RecommendedProduct.fromJson(json)).toList();
      return productList;
    } catch (e) {
      print('Error fetching recommended products: $e');
      rethrow;
    }
  }
}