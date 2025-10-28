import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/pet_text_field.dart';
import '../widgets/primary_button.dart';
import '../theme/app_theme.dart';
import 'package:pet_connect_app/screens/login_screen.dart';
import 'package:pet_connect_app/screens/profile_details_screen.dart';

class RegisterScreen extends StatefulWidget {
  static const routeName = '/register';
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email.text.trim(),
        password: password.text,
      );

      if (response.user != null) {
        await Supabase.instance.client.from('profiles').insert({
          'user_id': response.user!.id,
          'first_name': firstName.text.trim(),
          'last_name': lastName.text.trim(),
          'email': email.text.trim(),
        });

        if (!mounted) return;

        final signInResponse = await Supabase.instance.client.auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );

        if (signInResponse.user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful — complete profile details.')),
          );
          Navigator.pushReplacementNamed(context, ProfileDetailsScreen.routeName);
        }
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignIn() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9DF),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const Align(alignment: Alignment.bottomCenter, child: _WaveBands()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Text('Create your account', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  const SizedBox(height: 6),
                  Text('Sign up to get started', style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54)),
                  const SizedBox(height: 18),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: PetTextField(controller: firstName, hint: 'First name', icon: Icons.person_outline_rounded)),
                            const SizedBox(width: 12),
                            Expanded(child: PetTextField(controller: lastName, hint: 'Last name', icon: Icons.person_outline_rounded)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        PetTextField(controller: email, hint: 'Email', icon: Icons.alternate_email_rounded),
                        const SizedBox(height: 12),
                        PetTextField(controller: password, hint: 'Password', icon: Icons.lock_outline_rounded, obscure: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  _isLoading ? const Center(child: CircularProgressIndicator()) : PrimaryButton(label: 'Sign Up', icon: Icons.check_circle_rounded, onPressed: _submit),

                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Already have an account?', style: GoogleFonts.poppins()),
                    TextButton(onPressed: () => Navigator.pushReplacementNamed(context, LoginScreen.routeName), child: Text('Login', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)))
                  ]),

                  const SizedBox(height: 10),
                  Center(child: Text('Or continue with', style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54))),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _SocialIcon(onTap: _googleSignIn, child: const Icon(Icons.g_mobiledata)),
                    const SizedBox(width: 10),
                    _SocialIcon(child: const Icon(Icons.facebook_rounded)),
                    const SizedBox(width: 10),
                    _SocialIcon(child: const Icon(Icons.apple_rounded)),
                  ])
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
  final VoidCallback? onTap;
  const _SocialIcon({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
        child: Center(child: child),
      ),
    );
  }
}

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
  Widget build(BuildContext context) => ClipPath(clipper: _WaveClipper(), child: Container(height: height, color: color));
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
