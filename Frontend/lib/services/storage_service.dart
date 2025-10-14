import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class StorageService {
  // TODO: Replace with your backend URL
  static const String _baseUrl = 'http://localhost:8080';

  Future<String?> uploadProfilePicture(String token, XFile image) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/storage/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final decodedBody = jsonDecode(responseBody);
        return decodedBody['photoUrl'];
      } else {
        print('Failed to upload profile picture. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }
}