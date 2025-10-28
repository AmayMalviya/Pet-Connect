import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/services/api_service.dart';
import 'package:pet_connect_app/models/user.dart' as pet_connect_user;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:pet_connect_app/services/storage_service.dart';

class VetProfileScreen extends StatefulWidget {
  static const routeName = '/vet-profile';
  const VetProfileScreen({super.key});

  @override
  State<VetProfileScreen> createState() => _VetProfileScreenState();
}

class _VetProfileScreenState extends State<VetProfileScreen> {
  pet_connect_user.User? _user;
  bool _isLoading = true;
  String? _error;
  File? _profileImage;

  final _formKey = GlobalKey<FormState>();
  String _specialization = '';
  String _clinicAddress = '';

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        final fetchedUser = await ApiService.getUserDetails(currentUser.id);
        if (!mounted) return;
        setState(() {
          _user = fetchedUser;
          // TODO: Fetch vet specific data
        });
      } else {
        if (!mounted) return;
        setState(() {
          _error = 'User not logged in.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load profile data: ${e.toString()}';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      if (!mounted) return;
      setState(() {
        _profileImage = File(image.path);
      });
      await _uploadImage(image);
    }
  }

  Future<void> _uploadImage(XFile image) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to upload a profile picture.')),
        );
        return;
      }

      final storageService = StorageService();
      final imageUrl = await storageService.uploadProfilePicture(currentUser.id, image);

      await ApiService.updateUserPhoto(imageUrl!);
      _fetchProfileData(); // Refresh profile data to show new image

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload profile picture: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Profile"),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView( // Use SingleChildScrollView for better scrolling
                  padding: const EdgeInsets.all(24.0), // Increased padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card( // Card for profile header
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: _buildProfileHeader(_user?.displayName ?? 'N/A', _user?.email ?? 'N/A', _user?.photoUrl),
                        ),
                      ),
                      const SizedBox(height: 24), // Adjusted spacing
                      Card( // Card for profile form
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: _buildProfileForm(),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader(String name, String email, String? photoUrl) {
    bool isNetworkUrl = photoUrl != null && (photoUrl.startsWith('http://') || photoUrl.startsWith('https://'));

    return Column( // Changed to Column for better vertical alignment
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack( // Use Stack to overlay camera icon
            children: [
              CircleAvatar(
                radius: 50, // Increased size
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!) as ImageProvider
                    : (isNetworkUrl
                        ? NetworkImage(photoUrl!)
                        : const AssetImage('assets/images/profile_avatar.png') as ImageProvider),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), // Increased font size
        const SizedBox(height: 5),
        Text(email, style: const TextStyle(fontSize: 16, color: Colors.grey)), // Adjusted font size and color
      ],
    );
  }

  Widget _buildProfileForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Veterinarian Details',
            style: Theme.of(context).textTheme.headlineSmall, // Changed headline6 to headlineSmall
          ),
          const SizedBox(height: 20), // Adjusted spacing
          TextFormField(
            initialValue: _specialization,
            decoration: const InputDecoration(
              labelText: 'Specialization',
              border: OutlineInputBorder(), // Added border
            ),
            onSaved: (value) => _specialization = value!,
          ),
          const SizedBox(height: 20), // Adjusted spacing
          TextFormField(
            initialValue: _clinicAddress,
            decoration: const InputDecoration(
              labelText: 'Clinic Address',
              border: OutlineInputBorder(), // Added border
            ),
            onSaved: (value) => _clinicAddress = value!,
          ),
          const SizedBox(height: 30), // Adjusted spacing
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                // TODO: Save vet profile info
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'Save Profile',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}