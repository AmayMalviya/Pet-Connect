import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AuthScreen extends StatelessWidget {
  static const routeName = '/auth';
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // Waves (top-right & bottom)
          const _WaveBands(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Logo / Title
                  Column(
                    children: [
                      Icon(
                        Icons.pets_rounded,
                        size: 48,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Pet Connect",
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        "Find care • meet pet lovers",
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Welcome card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome!",
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Tap Login or Sign Up to continue.",
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 18),
                          PrimaryButton(
                            label: "Login",
                            icon: Icons.login_rounded,
                            onPressed: () => Navigator.pushReplacementNamed(
                              context,
                              LoginScreen.routeName,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.pushReplacementNamed(
                              context,
                              RegisterScreen.routeName,
                            ),
                            icon: const Icon(Icons.person_add_alt_1_rounded),
                            label: const Text("Create an account"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Private wavy painter to mimic the reference
class _WaveBands extends StatelessWidget {
  const _WaveBands();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // bottom bands
        Positioned(
          left: 0,
          right: 0,
          bottom: -6,
          child: _Band(height: 170, color: AppColors.accent),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 18,
          child: _Band(height: 150, color: AppColors.primary),
        ),
        // top-right soft curve
        Positioned(
          top: -10,
          right: -40,
          child: Transform.rotate(
            angle: -0.2,
            child: _Band(height: 140, width: 240, color: AppColors.accent),
          ),
        ),
      ],
    );
  }
}

class _Band extends StatelessWidget {
  final double height;
  final double? width;
  final Color color;
  const _Band({required this.height, required this.color, this.width});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        height: height,
        width: width ?? MediaQuery.of(context).size.width,
        color: color,
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.lineTo(0, size.height * 0.65);
    p.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.55,
      size.height * 0.74,
    );
    p.quadraticBezierTo(
      size.width * 0.82,
      size.height * 0.5,
      size.width,
      size.height * 0.7,
    );
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
