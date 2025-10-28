import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/pet_text_field.dart';
import '../widgets/primary_button.dart';
import '../theme/app_theme.dart';
import 'package:pet_connect_app/screens/login_screen.dart';

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
    if (firstName.text.isEmpty || lastName.text.isEmpty || email.text.isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email.text.trim(),
        password: password.text,
        data: {
          'first_name': firstName.text.trim(),
          'last_name': lastName.text.trim(),
        }, // Pass additional data
      );

      if (response.user != null) {
        // The user is created, but needs to confirm their email.
        // Supabase sends the confirmation email automatically if enabled.

        // We still need to create a profile in our public 'profiles' table.
        await Supabase.instance.client.from('profiles').insert({
          'user_id': response.user!.id,
          'first_name': firstName.text.trim(),
          'last_name': lastName.text.trim(),
          'email': email.text.trim(),
        });

        if (!mounted) return;

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Registration Successful'),
            content: const Text('Please check your email to verify your account before logging in.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.pushReplacementNamed(context, LoginScreen.routeName); // Go to login
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      final message = e.message.toLowerCase().contains('already registered')
          ? 'This email address is already in use.'
          : e.message;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignIn() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.petconnect://login-callback',
      );
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _appleSignIn() async {
    // TODO: Implement Apple Sign In with Supabase
  }

  Future<void> _facebookSignIn() async {
    // TODO: Implement Facebook Sign In with Supabase
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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

                  PetTextField(controller: firstName, hint: 'First name', icon: Icons.person_outline_rounded),
                  const SizedBox(height: 12),
                  PetTextField(controller: lastName, hint: 'Last name', icon: Icons.person_outline_rounded),
                  const SizedBox(height: 12),
                  PetTextField(controller: email, hint: 'Email', icon: Icons.alternate_email_rounded),
                  const SizedBox(height: 12),
                  PetTextField(controller: password, hint: 'Password', icon: Icons.lock_outline_rounded, obscure: true),

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
                    _SocialIcon(onTap: _facebookSignIn, child: const Icon(Icons.facebook_rounded)),
                    const SizedBox(width: 10),
                    _SocialIcon(onTap: _appleSignIn, child: const Icon(Icons.apple_rounded)),
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
    // Start by moving to a point on the left edge, which is the start of our wave
    p.moveTo(0, size.height * 0.7);
    // First curve of the wave
    p.quadraticBezierTo(size.width * 0.25, size.height * 0.5, size.width * 0.5, size.height * 0.7);
    // Second curve of the wave
    p.quadraticBezierTo(size.width * 0.75, size.height * 0.9, size.width, size.height * 0.7);
    // Line to the bottom-right corner
    p.lineTo(size.width, size.height);
    // Line to the bottom-left corner
    p.lineTo(0, size.height);
    // Close the path
    p.close();
    return p;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
