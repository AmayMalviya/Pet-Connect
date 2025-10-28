import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/pet_text_field.dart';
import '../widgets/primary_button.dart';
import '../theme/app_theme.dart';
import 'package:pet_connect_app/screens/role_selection_screen.dart';

class ProfileDetailsScreen extends StatefulWidget {
  static const routeName = '/profile-details';
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  final phone = TextEditingController();
  final city = TextEditingController();
  final stateCtrl = TextEditingController();
  final country = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    phone.dispose();
    city.dispose();
    stateCtrl.dispose();
    country.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final payload = {
        'user_id': user.id,
        if (phone.text.trim().isNotEmpty) 'phone': phone.text.trim(),
        if (city.text.trim().isNotEmpty) 'city': city.text.trim(),
        if (stateCtrl.text.trim().isNotEmpty) 'state': stateCtrl.text.trim(),
        if (country.text.trim().isNotEmpty) 'country': country.text.trim(),
      };

      await Supabase.instance.client.from('profiles').upsert(payload);

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, RoleSelectionScreen.routeName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save profile: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9DF),
      appBar: AppBar(
        title: const Text('Profile Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tell us a little more', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.primary)),
              const SizedBox(height: 12),

              PetTextField(controller: phone, hint: 'Phone', icon: Icons.phone_outlined),
              const SizedBox(height: 12),
              PetTextField(controller: city, hint: 'City', icon: Icons.location_city_outlined),
              const SizedBox(height: 12),
              PetTextField(controller: stateCtrl, hint: 'State', icon: Icons.map_outlined),
              const SizedBox(height: 12),
              PetTextField(controller: country, hint: 'Country', icon: Icons.public_outlined),

              const SizedBox(height: 20),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(label: 'Save & Continue', icon: Icons.save_outlined, onPressed: _saveProfile),
            ],
          ),
        ),
      ),
    );
  }
}
