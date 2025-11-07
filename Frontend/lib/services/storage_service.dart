import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class StorageService {
  final _supabase = Supabase.instance.client;

  // Upload a KYC file (aadhaar/selfie) into bucket `kyc_bucket`.
  /// Returns public URL on success or null on failure.
  Future<String?> uploadKycFile(String userId, File file, {required String purpose}) async {
    // purpose: 'aadhaar' or 'selfie' (used to build filename)
    try {
      final ext = p.extension(file.path);
      final filename = 'kyc/$userId/${purpose}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final bytes = await file.readAsBytes();

      // ensure bucket exists on Supabase side named 'kyc_bucket' (create in console)
      final res = await _supabase.storage.from('kyc_bucket').uploadBinary(
        filename,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      // getPublicUrl returns Map or string depending on version — handle both.
      final publicUrl = _supabase.storage.from('kyc_bucket').getPublicUrl(filename);

      return publicUrl;
    } catch (e) {
      // bubble up or log
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
}