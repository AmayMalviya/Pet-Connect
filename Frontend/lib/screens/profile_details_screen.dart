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
      final response = await Supabase.instance.client.from('indian_cities').select();
      _allLocations = (response as List)
          .where((item) => item != null)
          .map((item) => item as Map<String, dynamic>)
          .toList();
      
      _countries = _allLocations
          .where((e) => e['country'] != null)
          .map((e) => e['country'] as String)
          .toSet()
          .toList()..sort();
      print('Countries: $_countries');
      
    } catch (e) {
      // Handle error
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

              PetTextField(controller: phone, hintText: 'Phone'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                decoration: InputDecoration(
                  labelText: 'Country',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                items: _countries.map((String country) {
                  return DropdownMenuItem<String>(
                    value: country,
                    child: Text(country),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCountry = newValue;
                    _selectedState = null;
                    _selectedCity = null;
                    _states = _allLocations
                        .where((e) => e['country'] == newValue && e['State'] != null)
                        .map((e) => e['State'] as String)
                        .toSet()
                        .toList()..sort();
                    _cities = [];
                  });
                },
                validator: (value) => value == null ? 'Please select a country' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedState,
                decoration: InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                items: _states.map((String state) {
                  return DropdownMenuItem<String>(
                    value: state,
                    child: Text(state),
                  );
                }).toList(),
                onChanged: _selectedCountry == null ? null : (newValue) {
                  setState(() {
                    _selectedState = newValue;
                    _selectedCity = null;
                    _cities = _allLocations
                        .where((e) => e['country'] == _selectedCountry && e['State'] == newValue && e['City'] != null)
                        .map((e) => e['City'] as String)
                        .toSet()
                        .toList()..sort();
                  });
                },
                validator: (value) => value == null ? 'Please select a state' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCity,
                decoration: InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                items: _cities.map((String city) {
                  return DropdownMenuItem<String>(
                    value: city,
                    child: Text(city),
                  );
                }).toList(),
                onChanged: _selectedState == null ? null : (newValue) {
                  setState(() {
                    _selectedCity = newValue;
                  });
                },
                validator: (value) => value == null ? 'Please select a city' : null,
              ),

              const SizedBox(height: 20),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                      onPressed: _saveProfile,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_outlined),
                          SizedBox(width: 8),
                          Text('Save & Continue', style: TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
