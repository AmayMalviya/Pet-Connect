import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:pet_connect_app/models/shelter.dart';
import 'package:pet_connect_app/services/api_service.dart';
import 'package:pet_connect_app/screens/edit_shelter_profile_screen.dart';

class ShelterProfileScreen extends StatefulWidget {
  static const routeName = '/shelter-profile';

  const ShelterProfileScreen({super.key});

  @override
  State<ShelterProfileScreen> createState() => _ShelterProfileScreenState();
}

class _ShelterProfileScreenState extends State<ShelterProfileScreen> {
  Shelter? _shelter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchShelterData();
  }

  Future<void> _fetchShelterData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        final shelter = await ApiService.getShelter(user.uid);
        setState(() {
          _shelter = shelter;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shelter Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        leading: const BackButton(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              if (_shelter != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EditShelterProfileScreen(shelter: _shelter!),
                  ),
                ).then((_) => _fetchShelterData());
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 60,
                    backgroundImage: AssetImage('assets/images/logo.png'), // Placeholder
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _shelter?.user.displayName ?? 'Happy Paws Shelter',
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Non-Profit Pet Shelter',
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 30),
                  _buildProfileInfoCard(
                    context,
                    title: 'Contact Information',
                    info: {
                      'Email': _shelter?.user.email ?? 'contact@happypaws.org',
                      'Phone': _shelter?.phone ?? '+1 987 654 321',
                      'Address': _shelter?.address ?? '456 Rescue Road, Animal City',
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildProfileInfoCard(
                    context,
                    title: 'Shelter Details',
                    info: {
                      'Capacity': _shelter?.capacity ?? '50 Animals',
                      'Website': _shelter?.website ?? 'www.happypaws.org',
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileInfoCard(BuildContext context, {required String title, required Map<String, String> info}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20, thickness: 1),
            ...info.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key}: ',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
