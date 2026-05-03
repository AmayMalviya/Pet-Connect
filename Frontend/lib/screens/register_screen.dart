import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/pet_text_field.dart';
import '../widgets/primary_button.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

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
  final confirmPassword = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (email.text.isEmpty || password.text.isEmpty || firstName.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }
    if (password.text != confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email.text.trim(),
        password: password.text.trim(),
        data: {
          'first_name': firstName.text.trim(),
          'last_name': lastName.text.trim(),
        },
      );

      if (response.user != null) {
        // Write name + email into the profiles table immediately.
        // Supabase auth metadata (data: {}) is separate from the profiles table.
        try {
          await Supabase.instance.client.from('profiles').upsert({
            'user_id': response.user!.id,
            'first_name': firstName.text.trim(),
            'last_name': lastName.text.trim(),
            'email': email.text.trim(),
          });
        } catch (profileErr) {
          // Non-fatal: profile can be completed in ProfileSetupScreen
          debugPrint('Profile pre-fill warning: $profileErr');
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please login.')),
        );
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignIn() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.petconnect://login-callback',
      );
    } catch (e) {
      debugPrint('Google Sign In Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, automaticallyImplyLeading: false),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const Positioned.fill(child: _WaveBands()),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 12),
                          Text('Create your account', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary)),
                          const SizedBox(height: 6),
                          Text('Sign up to get started', style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54)),
                          const SizedBox(height: 18),

                          PetTextField(controller: firstName, hintText: 'First name'),
                          const SizedBox(height: 12),
                          PetTextField(controller: lastName, hintText: 'Last name'),
                          const SizedBox(height: 12),
                          PetTextField(controller: email, hintText: 'Email'),
                          const SizedBox(height: 12),
                          PetTextField(controller: password, hintText: 'Create Password', isPassword: true),
                          const SizedBox(height: 12),
                          PetTextField(controller: confirmPassword, hintText: 'Confirm Password', isPassword: true),

                          const SizedBox(height: 18),
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : PrimaryButton(
                                  onPressed: _submit,
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle_rounded),
                                      SizedBox(width: 8),
                                      Text('Sign Up', style: TextStyle(fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),

                          const SizedBox(height: 12),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('Already have an account?', style: GoogleFonts.poppins()),
                            TextButton(onPressed: () => Navigator.pushReplacementNamed(context, LoginScreen.routeName), child: Text('Login', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)))
                          ]),

                          const SizedBox(height: 10),
                          Center(child: Text('Or continue with', style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54))),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _SocialIcon(
                                onTap: _googleSignIn,
                                child: Image.network(
                                  'https://www.gstatic.com/images/branding/googleg/1x/googleg_standard_color_128dp.png',
                                  height: 24,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
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
      children: [
        // bottom bands
        Positioned(
          left: 0,
          right: 0,
          bottom: -6,
          child: _Band(height: 170, color: AppColors.accent, clipper: _BottomWaveClipper()),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 18,
          child: _Band(height: 150, color: AppColors.primary, clipper: _BottomWaveClipper()),
        ),
        // top-right soft curve
        Positioned(
          top: -10,
          right: -40,
          child: Transform.rotate(
            angle: -0.2,
            child: _Band(height: 140, width: 240, color: AppColors.accent, clipper: _TopWaveClipper()),
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
  final CustomClipper<Path> clipper;
  const _Band({required this.height, required this.color, this.width, required this.clipper});
  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: clipper,
      child: Container(
        height: height,
        width: width ?? MediaQuery.of(context).size.width,
        color: color,
      ),
    );
  }
}

class _BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.moveTo(0, size.height * 0.7);
    p.quadraticBezierTo(size.width * 0.25, size.height * 0.5, size.width * 0.5, size.height * 0.7);
    p.quadraticBezierTo(size.width * 0.75, size.height * 0.9, size.width, size.height * 0.7);
    p.lineTo(size.width, size.height);
    p.lineTo(0, size.height);
    p.close();
    return p;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _TopWaveClipper extends CustomClipper<Path> {
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
