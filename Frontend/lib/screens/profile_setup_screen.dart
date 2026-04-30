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
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _countryController;

  // Shelter-specific fields
  late TextEditingController _shelterNameController;
  late TextEditingController _websiteController;
  late TextEditingController _capacityController;
  late TextEditingController _experienceController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _countryController = TextEditingController();
    _shelterNameController = TextEditingController();
    _websiteController = TextEditingController();
    _capacityController = TextEditingController();
    _experienceController = TextEditingController();
    _loadExistingProfile(); // pre-fill from registration
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
        _cityController.text = data['city'] ?? '';
        _stateController.text = data['state'] ?? '';
        _countryController.text = data['country'] ?? '';
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
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _shelterNameController.dispose();
    _websiteController.dispose();
    _capacityController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
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
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'country': _countryController.text.trim(),
        'role': widget.role,
      };

      // Add shelter-specific fields if shelter
      if (widget.role == 'Shelter' || widget.role == 'Shelter Owner') {
        profileData['first_name'] = _shelterNameController.text.trim();
        profileData['website'] = _websiteController.text.trim();
        profileData['capacity'] = _capacityController.text.trim();
        profileData['experience'] = _experienceController.text.trim();
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
        const SizedBox(height: 16),
        _buildTextField(
          controller: _cityController,
          label: 'City',
          hint: 'Enter your city',
          icon: Icons.location_city,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'City is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _stateController,
          label: 'State',
          hint: 'Enter your state',
          icon: Icons.map,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'State is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _countryController,
          label: 'Country',
          hint: 'Enter your country',
          icon: Icons.public,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Country is required';
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
          controller: _cityController,
          label: 'City',
          hint: 'Enter your city',
          icon: Icons.location_city,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'City is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _stateController,
          label: 'State',
          hint: 'Enter your state',
          icon: Icons.map,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'State is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _countryController,
          label: 'Country',
          hint: 'Enter your country',
          icon: Icons.public,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Country is required';
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
        const SizedBox(height: 16),
        _buildTextField(
          controller: _capacityController,
          label: 'Shelter Capacity',
          hint: 'Enter number of animals',
          icon: Icons.pets,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Capacity is required';
            }
            if (int.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _experienceController,
          label: 'Experience',
          hint: 'Describe your shelter experience',
          icon: Icons.info,
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Experience is required';
            }
            return null;
          },
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
