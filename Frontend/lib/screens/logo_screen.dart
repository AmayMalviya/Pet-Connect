import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pet_connect_app/screens/auth_screen.dart';
import 'package:pet_connect_app/theme/app_theme.dart';

class LogoScreen extends StatefulWidget {
  const LogoScreen({super.key});

  @override
  State<LogoScreen> createState() => _LogoScreenState();
}

class _LogoScreenState extends State<LogoScreen> {
  @override
  void initState() {
    super.initState();
    Timer(
      const Duration(seconds: 2),
      () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Use app's background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Pet Connect',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppColors.primary, // Use app's primary color
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'fur-tastic Care Starts Here',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w300, // Lighter weight
                color: AppColors.textDark, // Use app's text color
              ),
            ),
          ],
        ),
      ),
    );
  }
}
