import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:pet_connect_app/services/api_service.dart';
import 'package:pet_connect_app/models/user.dart' as pet_connect_user;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ShelterProfileScreen extends StatefulWidget {
  static const routeName = '/shelter-profile';
  const ShelterProfileScreen({super.key});

  @override
  State<ShelterProfileScreen> createState() => _ShelterProfileScreenState();
}

class _ShelterProfileScreenState extends State<ShelterProfileScreen> {
  pet_connect_user.User? _user;
  bool _isLoading = true;
  String? _error;
  File? _profileImage;

  final _formKey = GlobalKey<FormState>();
  String _shelterName = '';
  String _shelterAddress = '';
  String _shelterContact = '';

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
      final firebase_auth.User? currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final fetchedUser = await ApiService.getUserDetails(currentUser.uid);
        if (!mounted) return;
        setState(() {
          _user = fetchedUser;
          // TODO: Fetch shelter specific data
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
      await _uploadImage(_profileImage!);
    }
  }

  Future<void> _uploadImage(File image) async {
    try {
      final firebase_auth.User? currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to upload a profile picture.')),
        );
        return;
      }

      final storageRef = FirebaseStorage.instance.ref().child('profile_pictures').child('${currentUser.uid}.jpg');
      await storageRef.putFile(image);
      final imageUrl = await storageRef.getDownloadURL();

      await currentUser.updatePhotoURL(imageUrl);
      await currentUser.reload();
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
        leading: const BackButton(), // Added back button
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
            'Shelter Details',
            style: Theme.of(context).textTheme.headlineSmall, // Changed headline6 to headlineSmall
          ),
          const SizedBox(height: 20), // Adjusted spacing
          TextFormField(
            initialValue: _shelterName,
            decoration: const InputDecoration(
              labelText: 'Shelter Name',
              border: OutlineInputBorder(), // Added border
            ),
            onSaved: (value) => _shelterName = value!,
          ),
          const SizedBox(height: 20), // Adjusted spacing
          TextFormField(
            initialValue: _shelterAddress,
            decoration: const InputDecoration(
              labelText: 'Shelter Address',
              border: OutlineInputBorder(), // Added border
            ),
            onSaved: (value) => _shelterAddress = value!,
          ),
          const SizedBox(height: 20), // Adjusted spacing
          TextFormField(
            initialValue: _shelterContact,
            decoration: const InputDecoration(
              labelText: 'Shelter Contact',
              border: OutlineInputBorder(), // Added border
            ),
            onSaved: (value) => _shelterContact = value!,
          ),
          const SizedBox(height: 30), // Adjusted spacing
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                // TODO: Save shelter profile info
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
