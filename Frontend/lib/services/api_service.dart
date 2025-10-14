import 'dart:convert';
import 'package:pet_connect_app/models/cat_breed.dart';
import 'package:pet_connect_app/models/dog_breed.dart';
import 'package:pet_connect_app/models/user.dart' as pet_connect_user;
import 'package:pet_connect_app/models/pet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:8080'; // Your backend URL

  static Future<void> synchronizeUser() async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      // This should not happen if the user is logged in
      return;
    }

    try {
      final idToken = await user.getIdToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/users/sync'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode != 200) {
        // Handle non-200 responses
        print('Failed to synchronize user. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to synchronize user');
      }
    } catch (e) {
      print('An error occurred during user synchronization: $e');
      throw Exception('Failed to synchronize user');
    }
  }

  static Future<pet_connect_user.User> getUserDetails() async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    try {
      final idToken = await user.getIdToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/users/me'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        return pet_connect_user.User.fromJson(jsonDecode(response.body));
      } else {
        print('Failed to get user details. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to get user details from backend');
      }
    } catch (e) {
      print('An error occurred while getting user details: $e');
      throw Exception('Failed to get user details from backend');
    }
  }

  static Future<void> updateUserPhoto(String photoUrl) async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    try {
      final idToken = await user.getIdToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/api/users/me/photo'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'photoUrl': photoUrl}),
      );

      if (response.statusCode != 200) {
        print('Failed to update user photo. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to update user photo');
      }
    } catch (e) {
      print('An error occurred while updating user photo: $e');
      throw Exception('Failed to update user photo');
    }
  }

  // No longer a TODO, this is now implemented in the backend
  static Future<Pet> addPet(Pet pet) async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    try {
      final idToken = await user.getIdToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/pets'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(pet.toJson()),
      );

      if (response.statusCode == 200) {
        return Pet.fromJson(jsonDecode(response.body));
      } else {
        print('Failed to add pet. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to add pet');
      }
    } catch (e) {
      print('An error occurred while adding pet: $e');
      throw Exception('Failed to add pet');
    }
  }

  static Future<List<Pet>> getMyPets() async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    try {
      final idToken = await user.getIdToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/pets'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> petList = jsonDecode(response.body);
        return petList.map((json) => Pet.fromJson(json)).toList();
      } else {
        print('Failed to get pets. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to get pets');
      }
    } catch (e) {
      print('An error occurred while getting pets: $e');
      throw Exception('Failed to get pets');
    }
  }

  static Future<List<DogBreed>> getDogBreeds() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/breeds/dogs'));

      if (response.statusCode == 200) {
        final List<dynamic> breedList = jsonDecode(response.body);
        return breedList.map((json) => DogBreed.fromJson(json)).toList();
      } else {
        print('Failed to get dog breeds. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to get dog breeds');
      }
    } catch (e) {
      print('An error occurred while getting dog breeds: $e');
      throw Exception('Failed to get dog breeds');
    }
  }

  static Future<List<CatBreed>> getCatBreeds() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/breeds/cats'));

      if (response.statusCode == 200) {
        final List<dynamic> breedList = jsonDecode(response.body);
        return breedList.map((json) => CatBreed.fromJson(json)).toList();
      } else {
        print('Failed to get cat breeds. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to get cat breeds');
      }
    } catch (e) {
      print('An error occurred while getting cat breeds: $e');
      throw Exception('Failed to get cat breeds');
    }
  }
}
