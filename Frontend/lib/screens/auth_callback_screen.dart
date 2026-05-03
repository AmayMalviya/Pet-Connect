import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import '../theme/app_theme.dart';

class AuthCallbackScreen extends StatefulWidget {
  static const String routeName = '/auth-callback';

  const AuthCallbackScreen({super.key});

  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  bool _isLoading = true;
  String _statusMessage = 'Processing authentication...';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _handleAuthCallback();
  }

  Future<void> _handleAuthCallback() async {
    try {
      // First, try to get URI from route arguments (when navigated from deep link handler)
      final routeArgs = ModalRoute.of(context)?.settings.arguments;
      Uri? authUri;

      if (routeArgs is Uri) {
        authUri = routeArgs;
      } else {
        // Fallback: Get the initial link that opened the app
        final appLinks = AppLinks();
        authUri = await appLinks.getInitialLink();

        if (authUri == null) {
          // If no initial link, try to get the latest link
          authUri = await appLinks.getLatestLink();
        }
      }

      if (authUri != null && authUri.scheme == 'io.supabase.petconnect') {
        await _processAuthUri(authUri);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No valid authentication link found';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to process authentication: ${e.toString()}';
      });
    }
  }

  Future<void> _processAuthUri(Uri uri) async {
    try {
      setState(() {
        _statusMessage = 'Extracting session from URL...';
      });

      final supabase = Supabase.instance.client;
      final response = await supabase.auth.getSessionFromUrl(uri);
      final session = response.session;

      if (session != null) {
        setState(() {
          _statusMessage = 'Authentication successful!';
        });

        // Wait a moment to show success message
        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;

        // Determine the auth flow type from the URL fragment
        final fragment = uri.fragment;
        final queryParams = uri.queryParameters;

        // Check various auth flow indicators
        if (fragment.contains('type=recovery') ||
            queryParams['type'] == 'recovery' ||
            fragment.contains('password_recovery')) {
          // Password recovery flow
          Navigator.of(
            context,
          ).pushReplacementNamed('/reset-password', arguments: session);
        } else if (fragment.contains('type=signup') ||
            queryParams['type'] == 'signup' ||
            fragment.contains('email_confirmation')) {
          // Email confirmation after signup
          Navigator.of(context).pushReplacementNamed('/');
        } else if (fragment.contains('type=magiclink') ||
            queryParams['type'] == 'magiclink' ||
            fragment.contains('magic_link')) {
          // Magic link login
          Navigator.of(context).pushReplacementNamed('/');
        } else if (fragment.contains('type=invite') ||
            queryParams['type'] == 'invite') {
          // User invitation
          Navigator.of(context).pushReplacementNamed('/');
        } else {
          // Default: go to home
          Navigator.of(context).pushReplacementNamed('/');
        }
      } else {
        // Handle case where session extraction failed
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Unable to authenticate. The link may be invalid or expired.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Authentication failed: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 64, color: AppColors.primary),
              const SizedBox(height: 24),
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  _statusMessage,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ] else if (_errorMessage != null) ...[
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  child: const Text('Go to Login'),
                ),
              ] else ...[
                const Icon(Icons.check_circle, size: 48, color: Colors.green),
                const SizedBox(height: 16),
                const Text(
                  'Authentication successful!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
