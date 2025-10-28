import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/screens/role_selection_screen.dart';
import 'package:pet_connect_app/widgets/primary_button.dart';
import 'package:pet_connect_app/widgets/pet_text_field.dart';
import 'package:pet_connect_app/theme/app_theme.dart';

class SocialProfileSetupScreen extends StatefulWidget {
  static const routeName = '/social-profile-setup';
  const SocialProfileSetupScreen({super.key});

  @override
  State<SocialProfileSetupScreen> createState() => _SocialProfileSetupScreenState();
}

class _SocialProfileSetupScreenState extends State<SocialProfileSetupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both first and last name.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User is not authenticated');
      }

      await Supabase.instance.client.from('profiles').upsert({
        'user_id': user.id,
        'first_name': firstName,
        'last_name': lastName,
        'email': user.email, // Save email as well
      });

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, RoleSelectionScreen.routeName);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Your Profile', style: GoogleFonts.poppins()),
        automaticallyImplyLeading: false, // No back button
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              'Welcome!',
              style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'Please enter your name to continue.',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            PetTextField(
              controller: _firstNameController,
              hint: 'First Name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            PetTextField(
              controller: _lastNameController,
              hint: 'Last Name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : PrimaryButton(
                    label: 'Save and Continue',
                    onPressed: _saveProfile,
                    icon: Icons.check_circle_outline,
                  ),
          ],
        ),
      ),
    );
  }
}
