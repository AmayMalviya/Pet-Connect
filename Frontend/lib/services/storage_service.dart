import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class StorageService {
  final _supabase = Supabase.instance.client;

  // Upload a KYC file (aadhaar/selfie) into bucket `kyc_bucket`.
  /// Returns public URL on success or null on failure.
  Future<String?> uploadKycFile(String userId, File file, {required String purpose}) async {
    // purpose: 'aadhaar' or 'selfie'
    try {
      // Check auth session - uploads require an authenticated user for protected buckets
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Not authenticated: user must be signed in to upload KYC files.');
      }

      // Read original bytes
      final origBytes = await file.readAsBytes();

      // Try to decode and compress to JPG to reduce upload size (faster uploads)
      Uint8List bytesToUpload = origBytes;
      try {
        final decoded = img.decodeImage(origBytes);
        if (decoded != null) {
          // Resize if larger than 1280px on the longest side
          final maxDim = 1280;
          final shouldResize = decoded.width > maxDim || decoded.height > maxDim;
          final resized = shouldResize
              ? img.copyResize(decoded, width: decoded.width >= decoded.height ? maxDim : null, height: decoded.height > decoded.width ? maxDim : null)
              : decoded;

          // Encode as JPEG with reasonable quality to reduce payload
          final jpg = img.encodeJpg(resized, quality: 85);
          bytesToUpload = Uint8List.fromList(jpg);
        }
      } catch (e) {
        // If compression fails, fall back to original bytes
        print('StorageService: image compression failed, uploading original bytes: $e');
        bytesToUpload = origBytes;
      }

      // Retry with exponential backoff for transient failures (504, network blips)
      const maxAttempts = 3;
      int attempt = 0;
      while (true) {
        attempt++;
        try {
          // Upload to kyc_bucket with path: userId/purpose.png (e.g., user123/aadhaar.png)
          final uploadPath = '$userId/$purpose.png';
          
          await Supabase.instance.client.storage
              .from('kyc_bucket')
              .uploadBinary(
                uploadPath,
                bytesToUpload,
                fileOptions: const FileOptions(upsert: true),
              )
              .timeout(const Duration(seconds: 40));

          // Get public URL for uploaded file
          final publicUrl = Supabase.instance.client.storage
              .from('kyc_bucket')
              .getPublicUrl(uploadPath);

          return publicUrl;
        } catch (e) {
          // Inspect message for known cases
          final msg = e.toString();
          // If it's an authorization / policy problem, don't retry
          if (msg.contains('row-level security') || msg.contains('Unauthorized') || msg.contains('403')) {
            throw Exception('Supabase policy error during upload: $msg');
          }

          // For gateway/timeouts, retry a few times
          if (attempt >= maxAttempts) {
            throw Exception('Upload failed after $attempt attempts: $msg');
          }

          // Backoff delay: 500ms * 2^(attempt-1)
          final delayMs = 500 * (1 << (attempt - 1));
          await Future.delayed(Duration(milliseconds: delayMs));
          // retry loop
        }
      }
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