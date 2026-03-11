import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/models/dog_breed.dart';
import 'package:pet_connect_app/models/cat_breed.dart';

class BreedService {
  static final supabase = Supabase.instance.client;

  static Future<List<DogBreed>> getDogBreeds() async {
    try {
      // Use dogs_pet_data table as per DB schema
      final response = await supabase
          .from('dogs_pet_data')
          .select('id, breed_name')
          .order('breed_name');

      return (response as List)
          .map((breed) => DogBreed.fromJson(breed as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching dog breeds: $e');
      rethrow;
    }
  }

  static Future<List<CatBreed>> getCatBreeds() async {
    try {
      // Use cats_pet_data table as per DB schema
      final response = await supabase
          .from('cats_pet_data')
          .select('id, breed_name')
          .order('breed_name');

      return (response as List)
          .map((breed) => CatBreed.fromJson(breed as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching cat breeds: $e');
      rethrow;
    }
  }
}