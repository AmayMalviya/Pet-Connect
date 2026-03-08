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
    _authStateSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        // Handle password recovery
        Navigator.of(context).pushNamed(
          ResetPasswordScreen.routeName,
          arguments: data.session,
        );
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
