import 'package:flutter/material.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:pet_connect_app/screens/add_pet_screen.dart';
import 'package:pet_connect_app/screens/pet_profile_screen.dart';
import 'auth_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:pet_connect_app/services/api_service.dart';
import 'package:pet_connect_app/models/user.dart' as pet_connect_user;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  pet_connect_user.User? _user;
  List<Pet> _pets = [];
  bool _isLoading = true;
  String? _error;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final firebase_auth.User? currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final fetchedUser = await ApiService.getUserDetails();
        // TODO: Implement getPetsByOwnerUid in the backend and uncomment the following line.
        final List<Pet> fetchedPets = []; // await ApiService.getPetsByOwnerUid(currentUser.uid);
        setState(() {
          _user = fetchedUser;
          _pets = fetchedPets;
          if (currentUser.photoURL != null) {
            _profileImage = null; // Clear local image if Firebase has one
          }
        });
      } else {
        setState(() {
          _error = 'User not logged in.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile data: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
      await _uploadImage(_profileImage!);
    }
  }

  Future<void> _uploadImage(File image) async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to upload a profile picture.')),
        );
        return;
      }

      final supabase = Supabase.instance.client;
      final imageExtension = image.path.split('.').last;
      final imagePath = '/${user.uid}/profile.$imageExtension';

      await supabase.storage.from('avatars').upload(
            imagePath,
            image,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final imageUrl = supabase.storage.from('avatars').getPublicUrl(imagePath);

      await supabase.from('profiles').upsert({'id': user.uid, 'avatar_url': imageUrl});

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

  void _addPet(Pet pet) async {
    if (!mounted) return;
    try {
      final firebase_auth.User? currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        pet.ownerUid = currentUser.uid; // Assign owner UID before adding
        await ApiService.addPet(pet);
        await _fetchProfileData(); // Refresh pet list after adding
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet added successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to add a pet.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add pet: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Profile"),
        leading: const BackButton(), // Added back button
        actions: [
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await firebase_auth.FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildProfileHeader(_user?.displayName ?? 'N/A', _user?.email ?? 'N/A', _user?.photoUrl),
                    const SizedBox(height: 20),
                    _buildPetList(),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newPet = await Navigator.of(context).pushNamed(AddPetScreen.routeName);
          if (newPet != null && newPet is Pet) {
            _addPet(newPet);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProfileHeader(String name, String email, String? photoUrl) {
    bool isNetworkUrl = photoUrl != null && (photoUrl.startsWith('http://') || photoUrl.startsWith('https://'));

    return Row(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: CircleAvatar(
            radius: 40,
            backgroundImage: _profileImage != null
                ? FileImage(_profileImage!) as ImageProvider
                : (isNetworkUrl
                    ? NetworkImage(photoUrl)
                    : const AssetImage('assets/images/profile_avatar.png') as ImageProvider),
            child: _profileImage == null && !isNetworkUrl
                ? const Icon(Icons.camera_alt, size: 30, color: Colors.white70)
                : null,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(email),
          ],
        ),
      ],
    );
  }

  Widget _buildPetList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Pets',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _pets.isEmpty
            ? const Text('No pets added yet.')
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pets.length,
                itemBuilder: (context, index) {
                  final pet = _pets[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: AssetImage('assets/images/logo.png'), // Use pet image if available
                      ),
                      title: Text(pet.name),
                      subtitle: Text(pet.breed),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PetProfileScreen(pet: pet),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ],
    );
  }
}