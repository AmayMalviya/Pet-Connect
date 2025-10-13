import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pet_connect_app/models/user.dart' as pet_connect_user;
import 'package:pet_connect_app/models/pet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8089/api';

  static Future<Map<String, dynamic>> registerUser(pet_connect_user.User user) async {
    print('Sending registration request with body: ${jsonEncode(user.toJson())}');

    final response = await http.post(
      Uri.parse('$baseUrl/users/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to register user: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> loginUser(String idToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'idToken': idToken,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to login user: ${response.body}');
    }
  }

  static Future<pet_connect_user.User> getUserDetails(String uid) async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', uid)
        .single();

    return pet_connect_user.User.fromJson(response);
  }

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
}