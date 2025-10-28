import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/models/user.dart' as pet_connect_user;

/// Minimal ApiService used by a few profile screens.
///
/// This is intentionally small: it reads the user's profile from the
/// Supabase `profiles` table and exposes a helper to update the avatar URL.
class ApiService {
  /// Fetches user details from the `profiles` table and maps to our User model.
  /// Falls back to joining first_name/last_name into displayName.
  static Future<pet_connect_user.User?> getUserDetails(String userId) async {
    final client = Supabase.instance.client;
    final resp = await client.from('profiles').select('user_id, first_name, last_name, email, avatar_url').eq('user_id', userId).maybeSingle();

    if (resp == null) return null;

    final firstName = resp['first_name'] as String?;
    final lastName = resp['last_name'] as String?;
    final email = resp['email'] as String? ?? '';
    final avatar = resp['avatar_url'] as String?;

    final displayName = ((firstName ?? '') + ' ' + (lastName ?? '')).trim();

    return pet_connect_user.User(
      uid: resp['user_id'] ?? userId,
      email: email,
      displayName: displayName.isEmpty ? email.split('@').first : displayName,
      photoUrl: avatar,
    );
  }

  /// Updates the user's avatar URL in the `profiles` table.
  static Future<void> updateUserPhoto(String url) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await Supabase.instance.client.from('profiles').upsert({
      'user_id': user.id,
      'avatar_url': url,
    });
  }
}

