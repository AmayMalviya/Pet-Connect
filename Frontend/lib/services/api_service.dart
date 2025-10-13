import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:pet_connect_app/models/user.dart' as pet_connect_user;
import 'package:pet_connect_app/models/pet.dart';

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

  // TODO: Implement Pet endpoints in the Java backend and uncomment this section
  /*
  static Future<String> addPet(Pet pet) async {
    final supabase = Supabase.instance.client;
    final response = await supabase.from('pets').insert(pet.toJson()).select();
    return response.first['id'].toString();
  }

  static Future<List<Pet>> getPetsByOwnerUid(String ownerUid) async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('pets')
        .select()
        .eq('owner_id', ownerUid);

    return (response as List).map((pet) => Pet.fromJson(pet)).toList();
  }
  */
}
