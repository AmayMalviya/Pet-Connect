import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pet_connect_app/models/user.dart' as pet_connect_user;
import 'package:pet_connect_app/models/pet.dart';

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
    final response = await http.get(
      Uri.parse('$baseUrl/users/details/$uid'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      return pet_connect_user.User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user details: ${response.body}');
    }
  }

  static Future<String> addPet(Pet pet) async {
    final response = await http.post(
      Uri.parse('$baseUrl/pets/add'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(pet.toJson()),
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to add pet: ${response.body}');
    }
  }

  static Future<List<Pet>> getPetsByOwnerUid(String ownerUid) async {
    final response = await http.get(
      Uri.parse('$baseUrl/pets/owner/$ownerUid'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      Iterable l = json.decode(response.body);
      return List<Pet>.from(l.map((model) => Pet.fromJson(model)));
    } else {
      throw Exception('Failed to load pets: ${response.body}');
    }
  }
}
