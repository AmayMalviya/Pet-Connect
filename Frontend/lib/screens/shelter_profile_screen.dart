

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_connect_app/screens/edit_shelter_profile_screen.dart';
import 'auth_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/models/user.dart' as pet_connect_user;
import 'package:pet_connect_app/services/storage_service.dart';
import 'package:pet_connect_app/theme/app_theme.dart';

class ShelterProfileScreen extends StatefulWidget {
  static const routeName = '/shelter-profile';

  const ShelterProfileScreen({super.key});

  @override
  State<ShelterProfileScreen> createState() => _ShelterProfileScreenState();
}

class _ShelterProfileScreenState extends State<ShelterProfileScreen> {
  pet_connect_user.User? _user;
  String? _shelterPhone;
  String? _shelterAddress;
  String? _shelterWebsite; // optional
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
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        setState(() => _error = 'User not logged in.');
        return;
      }

      final userProfile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (userProfile == null) {
        setState(() => _error = 'No profile found.');
        return;
      }

      final fetchedUser = pet_connect_user.User(
        uid: currentUser.id,
        email: currentUser.email ?? '',
        displayName:
            '${userProfile['first_name'] ?? ''} ${userProfile['last_name'] ?? ''}'.trim(),
        photoUrl: userProfile['photo_url'],
        phone: userProfile['phone'],
        city: userProfile['city'],
        state: userProfile['state'],
        country: userProfile['country'],
      );

      setState(() {
        _user = fetchedUser;
        _shelterPhone = userProfile['phone'];
        _shelterAddress = userProfile['city'];
        _shelterWebsite = userProfile['website'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) await _uploadImage(image);
  }

  Future<void> _uploadImage(XFile image) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to upload a profile picture.')),
      );
      return;
    }

    try {
      final storageService = StorageService();
      final imageUrl = await storageService.uploadProfilePicture(user.id, image);

      if (imageUrl != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'photo_url': imageUrl}).eq('user_id', user.id);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        leading: const BackButton(),
        actions: [
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (route) => false,
              );
            },
          ),
        ],
        elevation: 1,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _fetchProfileData,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 20),
                      _buildShelterDetails(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    final isNetworkUrl = _user?.photoUrl != null &&
        (_user!.photoUrl!.startsWith('http://') || _user!.photoUrl!.startsWith('https://'));

    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 56,
                backgroundImage: isNetworkUrl
                    ? NetworkImage(_user!.photoUrl!)
                    : const AssetImage('assets/images/profile_avatar.png') as ImageProvider,
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          (_user?.displayName ?? '').trim().isEmpty ? 'No Name Provided' : (_user?.displayName ?? ''),
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        Text(
          _user?.email ?? 'No Email Provided',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildShelterDetails() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Shelter Details",
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.primary),
                    onPressed: () async {
                      final nameParts = (_user?.displayName ?? '').split(' ');
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(
                            initialData: {
                              'first_name': nameParts.isNotEmpty ? nameParts.first : '',
                              'last_name': nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
                              'email': _user?.email,
                              'phone': _shelterPhone,
                              'city': _user?.city,
                              'state': _user?.state,
                              'country': _user?.country,
                              'website': _shelterWebsite,
                              'address': _shelterAddress,
                            },
                            isShelter: true,
                          ),
                        ),
                      );
                      if (result == true) {
                        _fetchProfileData();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.phone, "Phone", _shelterPhone ?? "Not provided"),
            _buildDetailRow(Icons.location_on, "Address", _shelterAddress ?? "Not provided"),
            _buildDetailRow(Icons.web, "Website", _shelterWebsite ?? "Not provided"),
            _buildDetailRow(Icons.location_city, "City", _user?.city ?? "Not provided"),
            _buildDetailRow(Icons.map, "State", _user?.state ?? "Not provided"),
            _buildDetailRow(Icons.public, "Country", _user?.country ?? "Not provided"),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey[700])),
                Text(subtitle, style: GoogleFonts.poppins(color: AppColors.textDark, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
