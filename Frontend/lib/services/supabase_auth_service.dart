import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  static final SupabaseAuthService _instance = SupabaseAuthService._internal();
  factory SupabaseAuthService() => _instance;
  SupabaseAuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  /// Sign in with email and password
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Send magic link for passwordless sign in
  Future<void> signInWithMagicLink({
    required String email,
    String? redirectTo,
  }) async {
    await _supabase.auth.signInWithOtp(
      email: email,
      emailRedirectTo: redirectTo ?? _getDefaultRedirectUrl(),
    );
  }

  /// Send password reset email
  Future<void> resetPassword({
    required String email,
    String? redirectTo,
  }) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: redirectTo ?? _getDefaultRedirectUrl(),
    );
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Update user password
  Future<UserResponse> updatePassword(String password) async {
    return await _supabase.auth.updateUser(UserAttributes(password: password));
  }

  /// Extract session from URL (for deep linking)
  Future<Session?> getSessionFromUrl(Uri url) async {
    try {
      final response = await _supabase.auth.getSessionFromUrl(url);
      return response.session;
    } catch (e) {
      // Handle invalid/expired tokens
      return null;
    }
  }

  /// Get the default redirect URL for auth flows
  String _getDefaultRedirectUrl() {
    // For development, you might want different URLs
    // For production, this should be your app's deep link URL
    return 'io.supabase.petconnect://auth-callback';
  }

  /// Check if user is authenticated
  bool get isAuthenticated => currentSession != null;

  /// Listen to auth state changes
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  /// Refresh session
  Future<AuthResponse> refreshSession() async {
    return await _supabase.auth.refreshSession();
  }

  /// Resend email confirmation
  Future<void> resendEmailConfirmation({
    required String email,
    String? redirectTo,
  }) async {
    await _supabase.auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: redirectTo ?? _getDefaultRedirectUrl(),
    );
  }
}
