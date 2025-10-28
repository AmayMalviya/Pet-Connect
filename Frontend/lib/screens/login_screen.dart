import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/pet_text_field.dart';
import '../widgets/primary_button.dart';
import '../theme/app_theme.dart';
import 'package:pet_connect_app/screens/register_screen.dart';
import 'package:pet_connect_app/screens/role_selection_screen.dart';
import 'package:pet_connect_app/screens/main_screen.dart';
import 'package:pet_connect_app/screens/kyc_screen.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void _submit() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email.text,
        password: password.text,
      );

      if (response.user != null) {
        final userData = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('user_id', response.user!.id)
            .maybeSingle();

        if (!mounted) return;

        if (userData?['role'] != null) {
          // User has already selected a role
          final role = userData!['role'] as String;
          if (role == 'Pet Owner') {
            Navigator.pushReplacementNamed(context, MainScreen.routeName);
          } else if (role == 'Vet' || role == 'Shelter Owner') {
            Navigator.pushReplacementNamed(context, KycScreen.routeName, arguments: role);
          }
        } else {
          // User hasn't selected a role yet
          Navigator.pushReplacementNamed(context, RoleSelectionScreen.routeName);
        }
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetPassword() async {
    if (email.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email to reset password.')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email.text);
      
      if (!mounted) return;
      
      // Show a dialog with instructions
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Password Reset Email Sent'),
          content: Text('A password reset link has been sent to ${email.text}. Please check your email to reset your password.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _googleSignIn() async {
    // TODO: Implement Google Sign in with Supabase
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
          Align(
            alignment: Alignment.bottomCenter,
            child: const _WaveBands(),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60), // Adjusted spacing
                  Text(
                    "Welcome!",
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Login to continue",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 48),
                  PetTextField(
                    controller: email,
                    hint: "Email",
                    icon: Icons.alternate_email_rounded,
                  ),
                  const SizedBox(height: 16),
                  PetTextField(
                    controller: password,
                    hint: "Password",
                    icon: Icons.lock_outline_rounded,
                    obscure: true,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _resetPassword,
                      child: Text(
                        'Forgot Password?',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : PrimaryButton(
                          label: "Login",
                          icon: Icons.login_rounded,
                          onPressed: _submit,
                        ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: GoogleFonts.poppins(),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, RegisterScreen.routeName);
                        },
                        child: Text(
                          'Register',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialIcon(onTap: _googleSignIn, child: const Icon(Icons.g_mobiledata)),  // placeholder
                      const SizedBox(width: 10),
                      _SocialIcon(child: const Icon(Icons.facebook)),
                      const SizedBox(width: 10),
                      _SocialIcon(child: const Icon(Icons.apple)),
                    ],
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
  final VoidCallback? onTap;
  const _SocialIcon({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44, width: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Center(child: child),
      ),
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
