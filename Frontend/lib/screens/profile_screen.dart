import 'package:flutter/material.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:pet_connect_app/screens/add_pet_screen.dart';
import 'package:pet_connect_app/screens/pet_profile_screen.dart';
import 'auth_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:pet_connect_app/services/api_service.dart';
import 'package:pet_connect_app/models/user.dart' as pet_connect_user;
import 'package:pet_connect_app/services/storage_service.dart';

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
        final List<Pet> fetchedPets = await ApiService.getPetsByOwnerId(currentUser.uid);
        setState(() {
          _user = fetchedUser;
          _pets = fetchedPets;
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
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (image != null) {
      await _uploadImage(image);
    }
  }

  Future<void> _uploadImage(XFile image) async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to upload a profile picture.')),
      );
      return;
    }

    try {
      final storageService = StorageService();
      final imageUrl = await storageService.uploadProfilePicture(user.uid, image);

      if (imageUrl != null) {
        // Now update the user profile via your backend
        await ApiService.updateUserPhoto(imageUrl);

        // Refresh profile data to show new image
        await _fetchProfileData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully!')),
        );
      } else {
        throw Exception('Upload returned a null URL.');
      }
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
            backgroundImage: isNetworkUrl
                ? NetworkImage(photoUrl!)
                : const AssetImage('assets/images/profile_avatar.png') as ImageProvider,
            child: !isNetworkUrl
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