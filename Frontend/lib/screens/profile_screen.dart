import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:pet_connect_app/screens/add_edit_pet_screen.dart';
import 'package:pet_connect_app/screens/add_pet_screen.dart';
import 'package:pet_connect_app/screens/edit_profile_screen.dart';
import 'auth_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/models/user.dart' as pet_connect_user;
import 'package:pet_connect_app/services/storage_service.dart';
import 'package:pet_connect_app/screens/health_details_screen.dart';
import 'package:pet_connect_app/theme/app_theme.dart';

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
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        final userProfile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('user_id', currentUser.id)
            .maybeSingle();

        final fetchedUser = pet_connect_user.User(
          uid: currentUser.id,
          email: currentUser.email!,
          displayName: userProfile != null && userProfile['first_name'] != null
              ? '${userProfile['first_name']} ${userProfile['last_name'] ?? ''}'
              : '',
          photoUrl: userProfile?['photo_url'],
          phone: userProfile?['phone'],
          city: userProfile?['city'],
          state: userProfile?['state'],
          country: userProfile?['country'],
        );

        final petsResponse = await Supabase.instance.client
            .from('pets')
            .select()
            .eq('owner_id', currentUser.id);

        final List<Pet> fetchedPets =
            (petsResponse as List).map((data) => Pet.fromJson(data)).toList();

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
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (image != null) {
      await _uploadImage(image);
    }
  }

  Future<void> _uploadImage(XFile image) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please log in to upload a profile picture.')),
      );
      return;
    }

    try {
      final storageService = StorageService();
      final imageUrl =
          await storageService.uploadProfilePicture(user.id, image);

      if (imageUrl != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'photo_url': imageUrl}).eq('user_id', user.id);

        await _fetchProfileData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile picture updated successfully!')),
        );
      } else {
        throw Exception('Upload returned a null URL.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to upload profile picture: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Your Profile", style: GoogleFonts.poppins(color: AppColors.textDark, fontWeight: FontWeight.w600)),
        leading: BackButton(color: AppColors.textDark),
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
        elevation: 0,
        backgroundColor: Colors.transparent,
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
                      _buildUserDetails(),
                      const SizedBox(height: 20),
                      _buildPetList(),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).pushNamed(AddPetScreen.routeName);
          if (result == true) {
            _fetchProfileData();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProfileHeader() {
    bool isNetworkUrl = _user?.photoUrl != null &&
        (_user!.photoUrl!.startsWith('http://') || _user!.photoUrl!.startsWith('https://'));

    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: CircleAvatar(
            radius: 50,
            backgroundImage: isNetworkUrl
                ? NetworkImage(_user!.photoUrl!)
                : const AssetImage('assets/images/profile_avatar.png')
                    as ImageProvider,
            child: Stack(
              children: [
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(_user?.displayName ?? 'N/A',
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(_user?.email ?? 'N/A', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
      ],
    );
  }

  Widget _buildUserDetails() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("My Details", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final nameParts = _user?.displayName?.split(' ');
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(
                          initialData: {
                            'first_name': nameParts?.first ?? '',
                            'last_name': (nameParts?.length ?? 0) > 1 ? nameParts?.last : '',
                            'email': _user?.email,
                            'phone': _user?.phone,
                            'city': _user?.city,
                            'state': _user?.state,
                            'country': _user?.country,
                          },
                        ),
                      ),
                    );
                    if (result == true) {
                      _fetchProfileData();
                    }
                  },
                ),
              ],
            ),
            const Divider(),
            _buildDetailRow(Icons.phone, "Phone", _user?.phone ?? "Not provided"),
            _buildDetailRow(Icons.location_on, "Location", 
              '${_user?.city ?? ''}, ${_user?.state ?? ''}, ${_user?.country ?? 'Not provided'}'),
          ],
        ),      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              Text(subtitle, style: GoogleFonts.poppins(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPetList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Pets',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _pets.isEmpty
            ? const Center(child: Text('No pets added yet.'))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pets.length,
                itemBuilder: (context, index) {
                  final pet = _pets[index];
                  return ExpandablePetCard(pet: pet, onPetUpdated: _fetchProfileData);
                },
              ),
      ],
    );
  }
}

class ExpandablePetCard extends StatefulWidget {
  final Pet pet;
  final VoidCallback onPetUpdated;

  const ExpandablePetCard(
      {Key? key, required this.pet, required this.onPetUpdated})
      : super(key: key);

  @override
  _ExpandablePetCardState createState() => _ExpandablePetCardState();
}

class _ExpandablePetCardState extends State<ExpandablePetCard> {
  bool _isExpanded = false;

  Future<void> _pickAndUploadPetImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (image != null) {
      final storageService = StorageService();
      final imageUrl = await storageService.uploadPetPicture(widget.pet.id!, image);
      if (imageUrl != null) {
        await Supabase.instance.client
            .from('pets')
            .update({'photo_url': imageUrl}).eq('id', widget.pet.id!);
        widget.onPetUpdated();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isNetworkUrl = widget.pet.photoUrl != null &&
        (widget.pet.photoUrl!.startsWith('http://') ||
            widget.pet.photoUrl!.startsWith('https://'));
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _pickAndUploadPetImage,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          ),
                          child: CircleAvatar(
                            radius: 34,
                            backgroundImage: isNetworkUrl
                                ? NetworkImage(widget.pet.photoUrl!)
                                : const AssetImage('assets/images/logo.png') as ImageProvider,
                            child: Stack(
                              children: [
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.pet.name ?? 'Unknown Pet', 
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textDark)
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.pet.breed ?? 'Unknown Breed', 
                              style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14)
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(height: 0, width: double.infinity),
              secondChild: Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: Colors.grey[200]),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Age: ${widget.pet.age} yrs', 
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.orange[800])
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.edit, size: 18),
                          label: Text('Edit Info', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                          ),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddEditPetScreen(pet: widget.pet),
                              ),
                            );
                            widget.onPetUpdated();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.monitor_heart_outlined, color: Colors.white),
                        label: Text('Health Calendar', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HealthDetailsScreen(petId: widget.pet.id!),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }
}