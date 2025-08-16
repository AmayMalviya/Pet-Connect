import 'package:flutter/material.dart';
import '../widgets/pet_text_field.dart';
import '../widgets/primary_button.dart';
import '../models/profile_args.dart';
import '../theme/app_theme.dart';
import 'profile_screen.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void _submit() {
    final e = email.text.trim();
    final name = (e.isEmpty ? "Guest" : e.split('@').first.replaceAll('.', ' ')).trim();
    Navigator.pushReplacementNamed(
      context,
      ProfileScreen.routeName,
      arguments: ProfileArgs(name: _titleCase(name), email: e.isEmpty ? "guest@example.com" : e),
    );
  }

  String _titleCase(String s) => s.isEmpty
      ? s
      : s.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: Stack(
        children: [
          const _WaveBands(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.pets_rounded, size: 40, color: AppColors.primary),
                        const SizedBox(height: 6),
                        Text("Pet Connect", style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text("Welcome back 👋", style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text("Login to continue", style: t.bodyMedium?.copyWith(color: Colors.black54)),
                  const SizedBox(height: 18),
                  PetTextField(controller: email, hint: "Email", icon: Icons.alternate_email_rounded),
                  const SizedBox(height: 12),
                  PetTextField(controller: password, hint: "Password", icon: Icons.lock_outline_rounded, obscure: true),
                  const SizedBox(height: 20),
                  PrimaryButton(label: "Login", icon: Icons.login_rounded, onPressed: _submit),
                  const SizedBox(height: 18),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SocialIcon(child: const Icon(Icons.g_mobiledata)),  // placeholder
                        const SizedBox(width: 10),
                        _SocialIcon(child: const Icon(Icons.facebook)),
                        const SizedBox(width: 10),
                        _SocialIcon(child: const Icon(Icons.apple)),
                      ],
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

class _SocialIcon extends StatelessWidget {
  final Widget child;
  const _SocialIcon({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44, width: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Center(child: child),
    );
  }
}

// private wave widgets (same style as auth)
class _WaveBands extends StatelessWidget {
  const _WaveBands();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        Positioned(left: 0, right: 0, bottom: -6, child: _Band(height: 170, color: AppColors.accent)),
        Positioned(left: 0, right: 0, bottom: 18, child: _Band(height: 150, color: AppColors.primary)),
      ],
    );
  }
}

class _Band extends StatelessWidget {
  final double height;
  final Color color;
  const _Band({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(height: height, color: color),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.lineTo(0, size.height * 0.65);
    p.quadraticBezierTo(size.width * 0.25, size.height, size.width * 0.55, size.height * 0.74);
    p.quadraticBezierTo(size.width * 0.82, size.height * 0.5, size.width, size.height * 0.7);
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
