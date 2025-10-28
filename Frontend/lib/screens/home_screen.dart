import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/screens/add_pet_screen.dart';
import 'package:pet_connect_app/theme/app_theme.dart';
import 'package:pet_connect_app/screens/adoption_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/screens/services_screen.dart'; // Import ServicesScreen
// Import SelfCareOptionsScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final bool _hasPet = false; // In a real app, this would come from a state management solution
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  void _loadUserName() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.userMetadata?['full_name'] ?? 'User';
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else if (hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  final List<String> _vetNames = [
    'Dr. Aarav Sharma',
    'Dr. Vivaan Gupta',
    'Dr. Aditya Singh',
    'Dr. Ishaan Patel',
    'Dr. Reyansh Kumar',
  ];

  void _showAddPetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            title: const Text('Add a Pet'),
            content: const Text('Please add a pet to access this service.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, AddPetScreen.routeName);
                },
                child: const Text('Add Pet'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildHomeScreen();
  }

  Widget _buildHomeScreen() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getGreeting()}, ${_userName ?? 'User'}!',
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (!_hasPet)
              const SizedBox(height: 20),
            if (!_hasPet)
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, AddPetScreen.routeName);
                },
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: AppColors.primary, width: 1.5)
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, color: AppColors.primary, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Add Your Pet',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search for services, products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Pet care'),
            const SizedBox(height: 10),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  PetCareCard(
                    title: 'Grooming',
                    icon: Icons.cut,
                    onTap: () {
                      if (_hasPet) {
                        Navigator.pushNamed(context, ServicesScreen.routeName);
                      } else {
                        _showAddPetDialog();
                      }
                    },
                  ),
                  PetCareCard(
                    title: 'Training',
                    icon: Icons.school,
                    onTap: () {
                      if (_hasPet) {
                        Navigator.pushNamed(context, ServicesScreen.routeName);
                      }
                    },
                  ),
                  PetCareCard(
                    title: 'Vet',
                    icon: Icons.medical_services,
                    onTap: () {
                      if (_hasPet) {
                        Navigator.pushNamed(context, ServicesScreen.routeName);
                      }
                    },
                  ),
                  PetCareCard(
                    title: 'Adoption',
                    icon: Icons.favorite_border,
                    onTap: () {
                      if (_hasPet) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AdoptionScreen()));
                      } else {
                        _showAddPetDialog();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Nearby Vets'),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                final random = Random();
                final vetName = _vetNames[random.nextInt(_vetNames.length)];
                return VetCard(
                  name: vetName,
                  address: '123 Main Street, Anytown, USA',
                  rating: 4.5,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

class PetCareCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const PetCareCard({super.key, required this.title, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(right: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Theme.of(context).primaryColor),
              const SizedBox(height: 10),
              Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class VetCard extends StatelessWidget {
  final String name;
  final String address;
  final double rating;

  const VetCard({
    super.key,
    required this.name,
    required this.address,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage(
                'assets/images/logo.png',
              ), // Add vet image
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(address, style: GoogleFonts.poppins(color: AppColors.textDark)),
                ],
              ),
            ),
            Row(
              children: [
                const Icon(Icons.star, color: AppColors.primary),
                Text(
                  rating.toString(),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}