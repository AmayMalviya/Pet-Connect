import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/screens/add_pet_screen.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:pet_connect_app/theme/app_theme.dart';
import 'package:pet_connect_app/screens/adoption_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/screens/services_screen.dart';
import 'package:pet_connect_app/screens/grooming_details_screen.dart';
import 'package:pet_connect_app/screens/training_details_screen.dart';
import 'package:pet_connect_app/screens/map_screen.dart';
// Import SelfCareOptionsScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasPet = false;
  bool _isLoading = true;
  String? _userName;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Load user profile
        final profile = await Supabase.instance.client
          .from('profiles')
          .select('first_name, last_name')
          .eq('user_id', user.id)
          .maybeSingle();
        
        // Check if user has any pets
        final pets = await Supabase.instance.client
            .from('pets')
            .select('id')
            .eq('owner_id', user.id);
        
        setState(() {
          _userName = (profile != null) 
            ? '${profile['first_name'] ?? 'User'}'
            : 'User';
          _hasPet = (pets as List).isNotEmpty;
          _error = null;
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
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
             shape: RoundedRectangleBorder(
               borderRadius: BorderRadius.circular(16),
             ),
             title: Row(
               children: [
                 Icon(Icons.pets, color: AppColors.primary),
                 const SizedBox(width: 8),
                 const Text('Add Your Pet'),
               ],
             ),
             content: Column(
               mainAxisSize: MainAxisSize.min,
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   'You need to add a pet first to access this service.',
                   style: GoogleFonts.poppins(),
                 ),
                 const SizedBox(height: 8),
                 Text(
                   'Would you like to add your pet now?',
                   style: GoogleFonts.poppins(
                     color: Colors.grey[600],
                     fontSize: 14,
                   ),
                 ),
               ],
             ),
             actions: [
               TextButton(
                 onPressed: () => Navigator.of(context).pop(),
                 child: Text(
                   'Later',
                   style: GoogleFonts.poppins(color: Colors.grey),
                 ),
               ),
               ElevatedButton(
                 onPressed: () async {
                   Navigator.of(context).pop();
                   await _openAddPetAndSave();
                 },
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppColors.primary,
                   foregroundColor: Colors.white,
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(8),
                   ),
                 ),
                 child: Text(
                   'Add Pet',
                   style: GoogleFonts.poppins(),
                 ),
               ),
             ],
          ),
        );
      },
    );
  }

  Future<void> _openAddPetAndSave() async {
    final result = await Navigator.of(context).pushNamed(AddPetScreen.routeName);
    if (result == true) {
      if (!mounted) return;
      setState(() {
        _hasPet = true;
      });
      await _loadUserData(); // Reload user data to refresh pet list
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildHomeScreen();
  }

  Widget _buildHomeScreen() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getGreeting()}, ${_userName ?? 'User'}!',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (!_hasPet)
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: InkWell(
                  onTap: () async {
                    await _openAddPetAndSave();
                  },
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          AppColors.primary.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pets, color: AppColors.primary, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'Add Your First Pet',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (!_hasPet)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Add a pet to unlock all features',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
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
                        Navigator.pushNamed(context, GroomingDetailsScreen.routeName);
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
                        Navigator.pushNamed(context, TrainingDetailsScreen.routeName);
                      } else {
                        _showAddPetDialog();
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
                  PetCareCard(
                    title: 'Nearby Services',
                    icon: Icons.location_on,
                    onTap: () {
                      Navigator.pushNamed(context, MapScreen.routeName);
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