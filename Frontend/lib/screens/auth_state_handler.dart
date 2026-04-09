import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pet_connect_app/screens/reset_password_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthStateHandler extends StatefulWidget {
  final Widget child;
  const AuthStateHandler({super.key, required this.child});

  @override
  State<AuthStateHandler> createState() => _AuthStateHandlerState();
}

class _AuthStateHandlerState extends State<AuthStateHandler> {
  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((data) {
          final event = data.event;
          final session = data.session;

          switch (event) {
            case AuthChangeEvent.passwordRecovery:
              // Handle password recovery - navigate to reset password screen
              if (session != null) {
                Navigator.of(context).pushReplacementNamed(
                  ResetPasswordScreen.routeName,
                  arguments: session,
                );
              }
              break;

            case AuthChangeEvent.signedIn:
              // Handle successful sign in (including magic link and email confirmation)
              if (session != null) {
                // Check if this is a password recovery flow
                final uri = Uri.tryParse(session.accessToken);
                if (uri != null && uri.fragment.contains('type=recovery')) {
                  Navigator.of(context).pushReplacementNamed(
                    ResetPasswordScreen.routeName,
                    arguments: session,
                  );
                } else {
                  // Regular sign in - navigate to home
                  Navigator.of(context).pushReplacementNamed('/');
                }
              }
              break;

            case AuthChangeEvent.signedOut:
              // Handle sign out - navigate to auth screen
              Navigator.of(context).pushReplacementNamed('/');
              break;

            case AuthChangeEvent.tokenRefreshed:
              // Token refreshed - no navigation needed
              break;

            case AuthChangeEvent.userUpdated:
              // User updated - no navigation needed
              break;

            case AuthChangeEvent.userDeleted:
              // User deleted - navigate to auth screen
              Navigator.of(context).pushReplacementNamed('/');
              break;

            default:
              // Handle any other auth events
              break;
          }
        });
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
