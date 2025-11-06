import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:pet_connect_app/screens/shelter_home_screen.dart';

class KycScreen extends StatefulWidget {
  static const routeName = '/kyc-screen';

  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _licenseNumber = '';
  File? _licenseImage;
  String? role;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    role = ModalRoute.of(context)?.settings.arguments as String?;
  }

  Future<void> _pickLicenseImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _licenseImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Verification'),
        centerTitle: true,
        leading: const BackButton(), // Added back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          'Personal Information', // Added title
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 20), // Adjusted spacing
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _name = value!;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'License Number',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your license number';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _licenseNumber = value!;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24), // Adjusted spacing
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          'License Upload', // Added title
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 20), // Adjusted spacing
                        _licenseImage == null
                            ? const Text('No license image selected.')
                            : Image.file(_licenseImage!, height: 200),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _pickLicenseImage,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload License'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      // TODO: Save KYC info and uploaded license
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('KYC information submitted')),
                      );
                      if (role == 'Shelter Owner') {
                        Navigator.of(context).pushReplacementNamed(ShelterHomeScreen.routeName);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}