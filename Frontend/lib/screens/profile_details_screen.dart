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
  bool _isLoading = false;

  List<Map<String, dynamic>> _allLocations = [];
  List<String> _countries = [];
  List<String> _states = [];
  List<String> _cities = [];

  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  @override
  void dispose() {
    phone.dispose();
    super.dispose();
  }

  Future<void> _fetchLocations() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('indian_cities')
          .select();
      _allLocations = (response as List)
          .where((item) => item != null)
          .map((item) => item as Map<String, dynamic>)
          .toList();
      _countries =
          _allLocations
              .where((e) => e['country'] != null)
              .map((e) => e['country'] as String)
              .toSet()
              .toList()
            ..sort();
    } catch (e) {
      debugPrint('Error fetching locations: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final payload = {
        'user_id': user.id,
        if (phone.text.trim().isNotEmpty) 'phone': phone.text.trim(),
        'city': _selectedCity,
        'state': _selectedState,
        'country': _selectedCountry,
      };

      await Supabase.instance.client.from('profiles').upsert(payload);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, RoleSelectionScreen.routeName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _dropdownDecor(String label) => InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
    filled: true,
    fillColor: Colors.grey[100],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Heading
              Text(
                'Tell us a little more',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Help us personalise your experience',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 28),

              // Phone
              _FieldLabel(label: 'Phone Number'),
              const SizedBox(height: 6),
              PetTextField(controller: phone, hintText: 'Phone'),
              const SizedBox(height: 18),

              // Country
              _FieldLabel(label: 'Country'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                decoration: _dropdownDecor('Select Country'),
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[500]),
                items: _countries
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCountry = newValue;
                    _selectedState = null;
                    _selectedCity = null;
                    _states =
                        _allLocations
                            .where(
                              (e) =>
                                  e['country'] == newValue &&
                                  e['State'] != null,
                            )
                            .map((e) => e['State'] as String)
                            .toSet()
                            .toList()
                          ..sort();
                    _cities = [];
                  });
                },
              ),
              const SizedBox(height: 14),

              // State
              _FieldLabel(label: 'State'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedState,
                decoration: _dropdownDecor('Select State'),
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[500]),
                items: _states
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: _selectedCountry == null
                    ? null
                    : (newValue) {
                        setState(() {
                          _selectedState = newValue;
                          _selectedCity = null;
                          _cities =
                              _allLocations
                                  .where(
                                    (e) =>
                                        e['country'] == _selectedCountry &&
                                        e['State'] == newValue &&
                                        e['City'] != null,
                                  )
                                  .map((e) => e['City'] as String)
                                  .toSet()
                                  .toList()
                                ..sort();
                        });
                      },
              ),
              const SizedBox(height: 14),

              // City
              _FieldLabel(label: 'City'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedCity,
                decoration: _dropdownDecor('Select City'),
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[500]),
                items: _cities
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: _selectedState == null
                    ? null
                    : (newValue) => setState(() => _selectedCity = newValue),
              ),
              const SizedBox(height: 28),

              // Save button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                      onPressed: _saveProfile,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_outlined),
                          SizedBox(width: 8),
                          Text(
                            'Save & Continue',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey[600],
      ),
    );
  }
}
