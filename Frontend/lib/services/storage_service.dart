import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class StorageService {
  final _supabase = Supabase.instance.client;

  // Upload a KYC file (aadhaar/selfie/zip) into bucket `kyc_bucket`.
  /// Returns storage path on success or null on failure.
  Future<String?> uploadKycFile(String userId, File file, {required String purpose, String? customFileName}) async {
    // purpose: 'aadhaar', 'selfie', 'aadhaar_zip'
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Not authenticated');
      }

      final origBytes = await file.readAsBytes();
      Uint8List bytesToUpload = origBytes;

      // Only attempt compression for images
      final extension = file.path.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png'].contains(extension)) {
        try {
          final decoded = img.decodeImage(origBytes);
          if (decoded != null) {
            final maxDim = 1280;
            final resized = (decoded.width > maxDim || decoded.height > maxDim)
                ? img.copyResize(decoded, width: decoded.width >= decoded.height ? maxDim : null, height: decoded.height > decoded.width ? maxDim : null)
                : decoded;
            bytesToUpload = Uint8List.fromList(img.encodeJpg(resized, quality: 85));
          }
        } catch (e) {
          print('StorageService: image compression failed: $e');
        }
      }

      final fileName = customFileName ?? '$purpose.$extension';
      final uploadPath = '$userId/$fileName';
      
      await _supabase.storage
          .from('kyc_bucket')
          .uploadBinary(
            uploadPath,
            bytesToUpload,
            fileOptions: const FileOptions(upsert: true),
          );

      return uploadPath;
    } catch (e) {
      print('StorageService.uploadKycFile error: $e');
      return null;
    }
  }

  Future<String?> uploadProfilePicture(String uid, XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      final fileExt = image.path.split('.').last;
      final fileName = '$uid.$fileExt';
      final filePath = fileName;

      await _supabase.storage.from('profile-pictures').uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final imageUrl = _supabase.storage.from('profile-pictures').getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }

  Future<String?> uploadPetPicture(String petId, XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      final fileExt = image.path.split('.').last;
      final fileName = '$petId.$fileExt';
      final filePath = fileName;

      await _supabase.storage.from('pet-pictures').uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final imageUrl = _supabase.storage.from('pet-pictures').getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      print('Error uploading pet picture: $e');
      return null;
    }
  }

  /// Generates a signed URL for a KYC file.
  /// path: The full path in the bucket (e.g., "userId/aadhaar.png")
  Future<String?> getKycSignedUrl(String path) async {
    try {
      final signedUrl = await _supabase.storage
          .from('kyc_bucket')
          .createSignedUrl(path, 3600);
      return signedUrl;
    } catch (e) {
      print('StorageService: Error generating signed URL for $path: $e');
      return null;
    }
  }
}