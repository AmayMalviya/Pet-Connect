import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/screens/main_screen.dart';
import 'package:pet_connect_app/screens/shelter_home_screen.dart';
import 'package:pet_connect_app/screens/kyc_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  static const routeName = '/profile-setup';

  final String role; // 'Pet Owner' or 'Shelter'

  const ProfileSetupScreen({super.key, required this.role});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Common fields
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  
  String? _countryValue;
  String? _stateValue;
  String? _cityValue;

  List<Map<String, dynamic>> _allLocations = [];
  List<String> _countries = [];
  List<String> _states = [];
  List<String> _cities = [];

  // Shelter-specific fields
  late TextEditingController _shelterNameController;
  late TextEditingController _websiteController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _shelterNameController = TextEditingController();
    _websiteController = TextEditingController();
    _fetchLocations();
    _loadExistingProfile(); // pre-fill from registration
  }

  Future<void> _fetchLocations() async {
    try {
      final response = await Supabase.instance.client
          .from('indian_cities')
          .select();
      _allLocations = (response as List)
          .where((item) => item != null)
          .map((item) => item as Map<String, dynamic>)
          .toList();
      setState(() {
        _countries =
            _allLocations
                .where((e) => e['country'] != null)
                .map((e) => e['country'] as String)
                .toSet()
                .toList()
              ..sort();
      });
    } catch (e) {
      debugPrint('Error fetching locations: $e');
    }
  }

  Future<void> _loadExistingProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('first_name, last_name, email, phone, city, state, country')
          .eq('user_id', user.id)
          .maybeSingle();
      if (data != null && mounted) {
        _firstNameController.text = data['first_name'] ?? '';
        _lastNameController.text = data['last_name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        setState(() {
          _cityValue = data['city'];
          _stateValue = data['state'];
          _countryValue = data['country'];
        });
      }
    } catch (e) {
      debugPrint('Could not pre-fill profile: $e');
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _shelterNameController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_countryValue == null || _stateValue == null || _cityValue == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Country, State, and City.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final profileData = {
        'user_id': user.id,
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _cityValue,
        'state': _stateValue,
        'country': _countryValue,
        'role': widget.role,
      };

      // Add shelter-specific fields if shelter
      if (widget.role == 'Shelter' || widget.role == 'Shelter Owner') {
        profileData['first_name'] = _shelterNameController.text.trim();
        profileData['website'] = _websiteController.text.trim();
      }

      await Supabase.instance.client.from('profiles').upsert(profileData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile setup completed successfully!')),
      );

      // Navigate based on role
      if (widget.role == 'Shelter' || widget.role == 'Shelter Owner') {
        // Shelter must complete KYC after profile setup
        Navigator.pushReplacementNamed(context, KycScreen.routeName);
      } else {
        Navigator.pushReplacementNamed(context, MainScreen.routeName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
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
        title: Text(
          '${widget.role} Profile Setup',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete Your Profile',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please provide your information to get started.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              if (widget.role == 'Pet Owner') _buildPetOwnerForm(),
              if (widget.role == 'Shelter' || widget.role == 'Shelter Owner') _buildShelterOwnerForm(),
              const SizedBox(height: 16),
              _buildLocationPicker(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Complete Setup',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dropdownDecor(String label) => InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
    filled: true,
    fillColor: Colors.grey[50],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  Widget _buildLocationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _countryValue,
          isExpanded: true,
          decoration: _dropdownDecor('Select Country'),
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[500]),
          items: _countries
              .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (newValue) {
            setState(() {
              _countryValue = newValue;
              _stateValue = null;
              _cityValue = null;
              _states = _allLocations
                  .where((e) => e['country'] == newValue && e['State'] != null)
                  .map((e) => e['State'] as String)
                  .toSet()
                  .toList()
                ..sort();
              _cities = [];
            });
          },
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: _stateValue,
          isExpanded: true,
          decoration: _dropdownDecor('Select State'),
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[500]),
          items: _states
              .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: _countryValue == null
              ? null
              : (newValue) {
                  setState(() {
                    _stateValue = newValue;
                    _cityValue = null;
                    _cities = _allLocations
                        .where((e) =>
                            e['country'] == _countryValue &&
                            e['State'] == newValue &&
                            e['City'] != null)
                        .map((e) => e['City'] as String)
                        .toSet()
                        .toList()
                      ..sort();
                  });
                },
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: _cityValue,
          isExpanded: true,
          decoration: _dropdownDecor('Select City'),
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[500]),
          items: _cities
              .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: _stateValue == null
              ? null
              : (newValue) => setState(() => _cityValue = newValue),
        ),
      ],
    );
  }

  Widget _buildPetOwnerForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _firstNameController,
          label: 'First Name',
          hint: 'Enter your first name',
          icon: Icons.person,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'First name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _lastNameController,
          label: 'Last Name',
          hint: 'Enter your last name',
          icon: Icons.person,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Last name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: 'Enter your phone number',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Phone number is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildShelterOwnerForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _shelterNameController,
          label: 'Shelter Name',
          hint: 'Enter your shelter name',
          icon: Icons.home,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Shelter name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: 'Enter your phone number',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Phone number is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _websiteController,
          label: 'Website (Optional)',
          hint: 'Enter your website URL',
          icon: Icons.language,
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
    );
  }
}
