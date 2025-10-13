import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditVetProfileScreen extends StatefulWidget {
  static const routeName = '/edit-vet-profile';
  // final Map<String, dynamic> vetData;

  // const EditVetProfileScreen({super.key, required this.vetData});
  const EditVetProfileScreen({super.key});

  @override
  State<EditVetProfileScreen> createState() => _EditVetProfileScreenState();
}

class _EditVetProfileScreenState extends State<EditVetProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _experienceController;
  late TextEditingController _specializationController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _experienceController = TextEditingController();
    _specializationController = TextEditingController();
    // _nameController = TextEditingController(text: widget.vetData['name']);
    // _phoneController = TextEditingController(text: widget.vetData['phone']);
    // _addressController = TextEditingController(text: widget.vetData['address']);
    // _experienceController = TextEditingController(text: widget.vetData['experience']);
    // _specializationController = TextEditingController(text: widget.vetData['specialization']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _experienceController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    // TODO: Implement Supabase
    // if (_formKey.currentState!.validate()) {
    //   try {
    //     final user = FirebaseAuth.instance.currentUser;
    //     if (user != null) {
    //       await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
    //         'name': _nameController.text,
    //         'phone': _phoneController.text,
    //         'address': _addressController.text,
    //         'experience': _experienceController.text,
    //         'specialization': _specializationController.text,
    //       });
    //       ScaffoldMessenger.of(context).showSnackBar(
    //         const SnackBar(content: Text('Profile updated successfully!')),
    //       );
    //       Navigator.of(context).pop();
    //     }
    //   } catch (e) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text('Failed to update profile: $e')),
    //     );
    //   }
    // }
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
                decoration: const InputDecoration(labelText: 'Name'),
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
                decoration: const InputDecoration(labelText: 'Clinic Address'),
                validator: (value) => value!.isEmpty ? 'Please enter an address' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _experienceController,
                decoration: const InputDecoration(labelText: 'Years of Experience'),
                validator: (value) => value!.isEmpty ? 'Please enter years of experience' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _specializationController,
                decoration: const InputDecoration(labelText: 'Specialization'),
                validator: (value) => value!.isEmpty ? 'Please enter a specialization' : null,
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