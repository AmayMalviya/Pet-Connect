import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  static const routeName = '/edit-profile';
  final Map<String, dynamic>? initialData;
  final bool isShelter;

  const EditProfileScreen({super.key, this.initialData, this.isShelter = false});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

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
    _firstNameController = TextEditingController(text: widget.initialData?['first_name'] ?? '');
    _lastNameController = TextEditingController(text: widget.initialData?['last_name'] ?? '');
    _emailController = TextEditingController(text: widget.initialData?['email'] ?? '');
    _phoneController = TextEditingController(text: widget.initialData?['phone'] ?? '');
    _addressController = TextEditingController(text: widget.initialData?['address'] ?? '');

    _selectedCountry = widget.initialData?['country'];
    _selectedState = widget.initialData?['state'];
    _selectedCity = widget.initialData?['city'];

    _fetchLocations();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
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
          .toList()
        ..sort();

      if (_selectedCountry != null) {
        _states = _allLocations
            .where((e) => e['country'] == _selectedCountry && e['State'] != null)
            .map((e) => e['State'] as String)
            .toSet()
            .toList()
          ..sort();
      }

      if (_selectedState != null) {
        _cities = _allLocations
            .where((e) =>
                e['country'] == _selectedCountry &&
                e['State'] == _selectedState &&
                e['City'] != null)
            .map((e) => e['City'] as String)
            .toSet()
            .toList()
          ..sort();
      }
    } catch (e) {
      debugPrint('Error fetching locations: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final profileUpdates = {
        'user_id': user.id,
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _selectedCity,
        'state': _selectedState,
        'country': _selectedCountry,
      };

      await Supabase.instance.client.from('profiles').upsert(profileUpdates);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _buildInputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary),
      fillColor: Colors.grey[50],
      filled: true,
      labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
      hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[200]!, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Edit Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
                            child: Text(
                              'Personal Information',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _firstNameController,
                            decoration: _buildInputDecoration('First Name', 'Enter your first name', Icons.person),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Please enter your first name'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _lastNameController,
                            decoration: _buildInputDecoration('Last Name', 'Enter your last name', Icons.person_outline),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Please enter your last name'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: _buildInputDecoration('Email', 'Enter your email', Icons.email),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            decoration: _buildInputDecoration('Phone Number', 'Enter your phone number', Icons.phone),
                            keyboardType: TextInputType.phone,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Please enter your phone number'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _addressController,
                            decoration: _buildInputDecoration('Address', 'Enter your address', Icons.location_on),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Please enter your address'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedCountry,
                            isExpanded: true,
                            decoration: _buildInputDecoration('Country', 'Select your country', Icons.public),
                            items: _countries.map((String country) {
                              return DropdownMenuItem<String>(
                                value: country,
                                child: Text(country, style: GoogleFonts.poppins()),
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
                                    .toList()
                                  ..sort();
                                _cities = [];
                              });
                            },
                            validator: (value) =>
                                value == null ? 'Please select a country' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedState,
                            isExpanded: true,
                            decoration: _buildInputDecoration('State', 'Select your state', Icons.map),
                            items: _states.map((String state) {
                              return DropdownMenuItem<String>(
                                value: state,
                                child: Text(state, style: GoogleFonts.poppins()),
                              );
                            }).toList(),
                            onChanged: _selectedCountry == null
                                ? null
                                : (newValue) {
                                    setState(() {
                                      _selectedState = newValue;
                                      _selectedCity = null;
                                      _cities = _allLocations
                                          .where((e) =>
                                              e['country'] == _selectedCountry &&
                                              e['State'] == newValue &&
                                              e['City'] != null)
                                          .map((e) => e['City'] as String)
                                          .toSet()
                                          .toList()
                                        ..sort();
                                    });
                                  },
                            validator: (value) =>
                                value == null ? 'Please select a state' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedCity,
                            isExpanded: true,
                            decoration: _buildInputDecoration('City', 'Select your city', Icons.location_city),
                            items: _cities.map((String city) {
                              return DropdownMenuItem<String>(
                                value: city,
                                child: Text(city, style: GoogleFonts.poppins()),
                              );
                            }).toList(),
                            onChanged: _selectedState == null
                                ? null
                                : (newValue) => setState(() {
                                      _selectedCity = newValue;
                                    }),
                            validator: (value) =>
                                value == null ? 'Please select a city' : null,
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text('Save Profile Updates', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
