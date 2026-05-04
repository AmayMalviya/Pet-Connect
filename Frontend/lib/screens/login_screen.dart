import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/pet_text_field.dart';
import '../widgets/primary_button.dart';
import '../theme/app_theme.dart';
import 'package:pet_connect_app/screens/register_screen.dart';
import 'package:pet_connect_app/screens/role_selection_screen.dart';
import 'package:pet_connect_app/screens/main_screen.dart';
import 'package:pet_connect_app/screens/shelter_home_screen.dart';
import 'package:pet_connect_app/screens/profile_details_screen.dart';
import 'package:pet_connect_app/screens/admin/admin_dashboard_screen.dart';
import 'package:pet_connect_app/screens/otp_screen.dart';

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
        if (!mounted) return;
        
        if (response.user!.email == 'malviyaamay501@gmail.com') {
          Navigator.pushReplacementNamed(context, AdminDashboardScreen.routeName);
          return;
        }

        final userData = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('user_id', response.user!.id)
            .maybeSingle();

        if (!mounted) return;

        if (userData == null || userData['phone'] == null || (userData['phone'] as String).isEmpty) {
          Navigator.pushReplacementNamed(context, ProfileDetailsScreen.routeName);
        } else if (userData['role'] != null) {
          final role = userData['role'] as String;
          if (role == 'Pet Owner') {
            Navigator.pushReplacementNamed(context, MainScreen.routeName);
          } else if (role == 'Shelter' || role == 'Shelter Owner') {
            Navigator.pushReplacementNamed(context, ShelterHomeScreen.routeName);
          }
        } else {
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
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email.text,
        redirectTo: 'io.supabase.petconnect://reset-password',
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset OTP sent! Please check your email.')),
      );
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            email: email.text.trim(),
            isPasswordReset: true,
          ),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      
      String errorMessage = e.message;
      if (e.message.toLowerCase().contains('user not found')) {
        errorMessage = 'No account found with this email address.';
      } else if (e.message.toLowerCase().contains('over_email_send_rate_limit')) {
        errorMessage = 'Too many reset attempts. Please try again later.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red.shade600,
        ),
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
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
                            const SizedBox(height: 60),
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
                              hintText: "Email",
                            ),
                            const SizedBox(height: 16),
                            PetTextField(
                              controller: password,
                              hintText: "Password",
                              isPassword: true,
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
                                    onPressed: _submit,
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.login_rounded),
                                        SizedBox(width: 8),
                                        Text("Login", style: TextStyle(fontWeight: FontWeight.w700)),
                                      ],
                                    ),
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
