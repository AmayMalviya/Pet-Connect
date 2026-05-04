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
              // Handle password recovery and other specific flows
              if (session != null) {
                final uri = Uri.tryParse(session.accessToken);
                if (uri != null && uri.fragment.contains('type=recovery')) {
                  Navigator.of(context).pushReplacementNamed(
                    ResetPasswordScreen.routeName,
                    arguments: session,
                  );
                }
                // Do NOT navigate to '/' here, StreamBuilder in main.dart handles it
              }
              break;

            case AuthChangeEvent.signedOut:
              // Do NOT navigate to '/' here, StreamBuilder in main.dart handles it
              break;

            case AuthChangeEvent.tokenRefreshed:
              // Token refreshed - no navigation needed
              break;

            case AuthChangeEvent.userUpdated:
              // User updated - no navigation needed
              break;

            case AuthChangeEvent.userDeleted:
              // User deleted - the StreamBuilder in main.dart will pick this up
              // as a signedOut event or null session and show AuthScreen automatically.
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
