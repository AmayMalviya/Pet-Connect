import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:pet_connect_app/models/vet.dart';
import 'package:pet_connect_app/services/api_service.dart';
import 'package:pet_connect_app/screens/edit_vet_profile_screen.dart';

class VetProfileScreen extends StatefulWidget {
  static const routeName = '/vet-profile';

  const VetProfileScreen({super.key});

  @override
  State<VetProfileScreen> createState() => _VetProfileScreenState();
}

class _VetProfileScreenState extends State<VetProfileScreen> {
  Vet? _vet;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVetData();
  }

  Future<void> _fetchVetData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        final vet = await ApiService.getVet(user.uid);
        setState(() {
          _vet = vet;
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
        title: Text('My Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        leading: const BackButton(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              if (_vet != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EditVetProfileScreen(vet: _vet!),
                  ),
                ).then((_) => _fetchVetData());
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
                    backgroundImage: AssetImage('assets/images/profile_avatar.png'), // Placeholder
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _vet?.user.displayName ?? 'Dr. John Doe',
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Veterinarian',
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 30),
                  _buildProfileInfoCard(
                    context,
                    title: 'Contact Information',
                    info: {
                      'Email': _vet?.user.email ?? 'john.doe@vet.com',
                      'Phone': _vet?.phone ?? '+1 234 567 890',
                      'Clinic Address': _vet?.address ?? '123 Pet Street, Animal City',
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildProfileInfoCard(
                    context,
                    title: 'Professional Details',
                    info: {
                      'Years of Experience': _vet?.yearsOfExperience.toString() ?? '10+',
                      'Specialization': _vet?.specialization ?? 'Small Animals',
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
