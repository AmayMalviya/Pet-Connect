import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/models/shelter.dart';
import 'package:pet_connect_app/services/api_service.dart';

class EditShelterProfileScreen extends StatefulWidget {
  static const routeName = '/edit-shelter-profile';
  final Shelter shelter;

  const EditShelterProfileScreen({super.key, required this.shelter});

  @override
  State<EditShelterProfileScreen> createState() => _EditShelterProfileScreenState();
}

class _EditShelterProfileScreenState extends State<EditShelterProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _capacityController;
  late TextEditingController _websiteController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shelter.user.displayName);
    _phoneController = TextEditingController(text: widget.shelter.phone);
    _addressController = TextEditingController(text: widget.shelter.address);
    _capacityController = TextEditingController(text: widget.shelter.capacity);
    _websiteController = TextEditingController(text: widget.shelter.website);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _capacityController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        final shelter = Shelter(
          id: widget.shelter.id,
          phone: _phoneController.text,
          address: _addressController.text,
          capacity: _capacityController.text,
          website: _websiteController.text,
          user: widget.shelter.user, // This will not be updated
        );

        await ApiService.saveShelter(shelter);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Shelter Name'),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (value) => value!.isEmpty ? 'Please enter a phone number' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (value) => value!.isEmpty ? 'Please enter an address' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(labelText: 'Capacity'),
                validator: (value) => value!.isEmpty ? 'Please enter the capacity' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(labelText: 'Website'),
                validator: (value) => value!.isEmpty ? 'Please enter a website' : null,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
