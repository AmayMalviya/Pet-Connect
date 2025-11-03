import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  static const routeName = '/edit-profile';
  final Map<String, dynamic>? initialData;

  const EditProfileScreen({super.key, this.initialData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

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

    _selectedCountry = widget.initialData?['country'];
    _selectedState = widget.initialData?['State'];
    _selectedCity = widget.initialData?['City'];

    _fetchLocations();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocations() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.from('indian_cities').select();
      print('Locations response: $response');
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
      
      if (_selectedCountry != null) {
        _states = _allLocations
            .where((e) => e['country'] == _selectedCountry && e['State'] != null)
            .map((e) => e['State'] as String)
            .toSet()
            .toList()..sort();
        print('States for $_selectedCountry: $_states');
      }
      if (_selectedState != null && !_states.contains(_selectedState)) { // Check if _selectedState is valid
        _selectedState = null;
      }
      if (_selectedState != null) {
        _cities = _allLocations
            .where((e) => e['country'] == _selectedCountry && e['State'] == _selectedState && e['City'] != null)
            .map((e) => e['City'] as String)
            .toSet()
            .toList()..sort();
        print('Cities for $_selectedState: $_cities');
      }
      if (_selectedCity != null && !_cities.contains(_selectedCity)) { // Check if _selectedCity is valid
        _selectedCity = null;
      }

    } catch (e) {
      print('Error fetching locations: $e');
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final updates = {
        'user_id': user.id,
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _selectedCity,
        'state': _selectedState,
        'country': _selectedCountry,
      };

      await Supabase.instance.client
          .from('profiles')
          .upsert(updates);

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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        leading: const BackButton(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Personal Information',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                labelText: 'First Name',
                                hintText: 'Enter your first name',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your first name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                labelText: 'Last Name',
                                hintText: 'Enter your last name',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your last name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'Enter your email',
                                prefixIcon: const Icon(Icons.email),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                              ),
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
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                hintText: 'Enter your phone number',
                                prefixIcon: const Icon(Icons.phone),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
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
                            const SizedBox(height: 16),
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
                            const SizedBox(height: 16),
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
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Profile',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
