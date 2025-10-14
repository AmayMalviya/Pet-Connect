import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:pet_connect_app/models/cat_breed.dart';
import 'package:pet_connect_app/models/dog_breed.dart';
import 'package:pet_connect_app/models/user.dart' as pet_connect_user;
import 'package:pet_connect_app/models/pet.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:8080'; // Your backend URL

  static Future<void> synchronizeUser() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
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
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
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
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
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
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
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

  static Future<Pet> updatePet(int id, Pet pet) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    try {
      final idToken = await user.getIdToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/api/pets/$id'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(pet.toJson()),
      );

      if (response.statusCode == 200) {
        return Pet.fromJson(jsonDecode(response.body));
      } else {
        print('Failed to update pet. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to update pet');
      }
    } catch (e) {
      print('An error occurred while updating pet: $e');
      throw Exception('Failed to update pet');
    }
  }

  static Future<void> deletePet(int id) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    try {
      final idToken = await user.getIdToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/pets/$id'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode != 204) {
        print('Failed to delete pet. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to delete pet');
      }
    } catch (e) {
      print('An error occurred while deleting pet: $e');
      throw Exception('Failed to delete pet');
    }
  }

  static Future<List<Pet>> getPetsByStatus(String status) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/pets/status/$status'));

      if (response.statusCode == 200) {
        final List<dynamic> petList = jsonDecode(response.body);
        return petList.map((json) => Pet.fromJson(json)).toList();
      } else {
        print('Failed to get pets by status. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to get pets by status');
      }
    } catch (e) {
      print('An error occurred while getting pets by status: $e');
      throw Exception('Failed to get pets by status');
    }
  }

  static Future<List<Pet>> getPetsByOwnerId(String ownerId) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    try {
      final idToken = await user.getIdToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/pets/owner/$ownerId'),
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

  static Future<List<AdoptionRequest>> getAdoptionRequestsByShelterOwnerId(String shelterOwnerId) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    try {
      final idToken = await user.getIdToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/adoption-requests/shelter/$shelterOwnerId'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> requestList = jsonDecode(response.body);
        // TODO: Get pet and user details for each request
        return requestList.map((json) => AdoptionRequest.fromJson(json)).toList();
      } else {
        print('Failed to get adoption requests. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to get adoption requests');
      }
    } catch (e) {
      print('An error occurred while getting adoption requests: $e');
      throw Exception('Failed to get adoption requests');
    }
  }

  static Future<AdoptionRequest> updateAdoptionRequestStatus(int id, String status) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    try {
      final idToken = await user.getIdToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/api/adoption-requests/$id/status'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(status),
      );

      if (response.statusCode == 200) {
        return AdoptionRequest.fromJson(jsonDecode(response.body));
      } else {
        print('Failed to update adoption request status. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to update adoption request status');
      }
    } catch (e) {
      print('An error occurred while updating adoption request status: $e');
      throw Exception('Failed to update adoption request status');
    }
  }

  static Future<List<Appointment>> getAppointmentsByVetId(String vetId) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    try {
      final idToken = await user.getIdToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/appointments/vet/$vetId'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> appointmentList = jsonDecode(response.body);
        return appointmentList.map((json) => Appointment.fromJson(json)).toList();
      } else {
        print('Failed to get appointments. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to get appointments');
      }
    } catch (e) {
      print('An error occurred while getting appointments: $e');
      throw Exception('Failed to get appointments');
    }
  }

  static Future<Appointment> updateAppointmentStatus(int id, String status) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    try {
      final idToken = await user.getIdToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/api/appointments/$id/status'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(status),
      );

      if (response.statusCode == 200) {
        return Appointment.fromJson(jsonDecode(response.body));
      } else {
        print('Failed to update appointment status. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to update appointment status');
      }
    } catch (e) {
      print('An error occurred while updating appointment status: $e');
      throw Exception('Failed to update appointment status');
    }
  }

  static Future<Shelter> getShelter(String id) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    try {
      final idToken = await user.getIdToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/shelters/$id'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        return Shelter.fromJson(jsonDecode(response.body));
      } else {
        print('Failed to get shelter. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to get shelter');
      }
    } catch (e) {
      print('An error occurred while getting shelter: $e');
      throw Exception('Failed to get shelter');
    }
  }

  static Future<Shelter> saveShelter(Shelter shelter) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    try {
      final idToken = await user.getIdToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/shelters'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(shelter.toJson()),
      );

      if (response.statusCode == 200) {
        return Shelter.fromJson(jsonDecode(response.body));
      } else {
        print('Failed to save shelter. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to save shelter');
      }
    } catch (e) {
      print('An error occurred while saving shelter: $e');
      throw Exception('Failed to save shelter');
    }
  }

  static Future<Vet> getVet(String id) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    try {
      final idToken = await user.getIdToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/vets/$id'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        return Vet.fromJson(jsonDecode(response.body));
      } else {
        print('Failed to get vet. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to get vet');
      }
    } catch (e) {
      print('An error occurred while getting vet: $e');
      throw Exception('Failed to get vet');
    }
  }

  static Future<Vet> saveVet(Vet vet) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    try {
      final idToken = await user.getIdToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/vets'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(vet.toJson()),
      );

      if (response.statusCode == 200) {
        return Vet.fromJson(jsonDecode(response.body));
      } else {
        print('Failed to save vet. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to save vet');
      }
    } catch (e) {
      print('An error occurred while saving vet: $e');
      throw Exception('Failed to save vet');
    }
  }
}
}
}
}