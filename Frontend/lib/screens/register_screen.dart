import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/pet_text_field.dart';
import '../widgets/primary_button.dart';
import '../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pet_connect_app/services/api_service.dart';
import 'package:pet_connect_app/models/user.dart' as pet_connect_user;
import 'package:pet_connect_app/screens/login_screen.dart';
import 'package:pet_connect_app/screens/role_selection_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegisterScreen extends StatefulWidget {
  static const routeName = '/register';
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void _submit() async {
    setState(() {
      _isLoading = true;
    });
    print('Attempting to register user...');
    try {
      print('Attempting Firebase user creation...');
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text,
        password: password.text,
      );
      print('Firebase user creation successful.');

      if (userCredential.user != null) {
        print('User credential user is not null. UID: ${userCredential.user!.uid}');
        // Update display name in Firebase Auth
        await userCredential.user!.updateDisplayName(name.text);
        print('Display name updated in Firebase Auth.');

        // Register user in backend
        pet_connect_user.User newUser = pet_connect_user.User(
          uid: userCredential.user!.uid,
          email: email.text,
          displayName: name.text,
        );
        print('Calling backend ApiService.registerUser...');
        await ApiService.registerUser(newUser);
        print('Backend registration successful.');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for signing up!')), 
        );
        print('Navigating to MainScreen...');
        Navigator.pushReplacementNamed(context, RoleSelectionScreen.routeName);
      } else {
        print('User credential user is null. Showing error snackbar.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to register user.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException caught: ${e.code} - ${e.message}');
      String message;
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else {
        message = e.message ?? 'An unknown error occurred.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      print('Generic exception caught: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
    setState(() {
      _isLoading = false;
    });
    print('Registration process finished. isLoading set to false.');
  }

  Future<void> _googleSignIn() async {
    try {
      final GoogleSignIn _googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      String? idToken = await userCredential.user?.getIdToken();
      if (idToken != null) {
        await ApiService.loginUser(idToken);
        Navigator.pushReplacementNamed(
          context,
          RoleSelectionScreen.routeName,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Changed to pop
          },
        ),
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
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60), // Adjusted spacing
                  Text(
                    "Create your account",
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Sign up to get started",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 48),
                  PetTextField(
                    controller: name,
                    hint: "Full name",
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : PrimaryButton(
                          label: "Sign Up",
                          icon: Icons.check_circle_rounded,
                          onPressed: _submit,
                        ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account?",
                        style: GoogleFonts.poppins(),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, LoginScreen.routeName);
                        },
                        child: Text(
                          'Login',
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
                  const SizedBox(height: 200), // Added space to avoid overlap with wave
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

// same waves as login
class _WaveBands extends StatelessWidget {
  const _WaveBands();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
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
