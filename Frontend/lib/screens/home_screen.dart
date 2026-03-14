import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/screens/add_edit_pet_screen.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:pet_connect_app/theme/app_theme.dart';
import 'package:pet_connect_app/screens/adoption_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/screens/services_screen.dart';
import 'package:pet_connect_app/screens/map_screen.dart';
import 'package:pet_connect_app/screens/pet_profile_screen.dart';
import 'package:pet_connect_app/screens/global_ai_chat_screen.dart';

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
  String? _firstName;
  String? _error;
  List<Pet> _myPets = [];
  List<String> _petNames = [];
  String _currentGreeting = 'Welcome back! 🐾';

  final List<String> _baseGreetings = [
    // General
    'Welcome back! Your pets are happy to see you. 🐾',
    'Hello again! Ready to check on your pets?',
    "Good to see you! Let's care for some happy pets.",
    'Welcome back to Pet Connect!',
    'Your pet world is waiting for you.',
    // Playful
    'A wagging tail is waiting somewhere! 🐶',
    'Your furry friends say hello!',
    'Someone just wagged their tail thinking about you.',
    'Time to spread some pawsitive vibes. 🐾',
    "Your pets' happiness starts here.",
    // Care & Health
    "Let's keep your pets happy and healthy today.",
    "Your pets' care journey continues.",
    "A happy pet is a healthy pet. Let's begin.",
    'Check in on your pets today.',
    'Small care today, big happiness tomorrow.',
    // Community
    "Let's see what the pet community is sharing today.",
    'Pet lovers are connecting right now.',
    'Your pet community is waiting.',
    'Discover stories from fellow pet parents.',
    "Let's connect with the pet world.",
    // Adoption
    'Some pets are waiting for a loving home today.',
    'Maybe today you meet your new best friend. 🐕',
    'Every pet deserves love.',
    "Let's help more pets find homes.",
    'Adoption stories start here.',
    // Minimal
    'Hello, pet parent!',
    'Welcome back. 🐾',
    'Ready for some pawsitive moments?',
    'Your pets await.',
    "Let's begin the pet journey.",
  ];

  @override
  void initState() {
    super.initState();
    _currentGreeting = _baseGreetings[Random().nextInt(_baseGreetings.length)];
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('first_name, last_name')
            .eq('user_id', user.id)
            .maybeSingle();

        final petsResponse = await Supabase.instance.client
            .from('pets')
            .select()
            .eq('owner_id', user.id);

        if (mounted) {
          setState(() {
            _firstName = profile?['first_name'] ?? 'User';
            _userName = _firstName;
            _hasPet = (petsResponse as List).isNotEmpty;
            if (_hasPet) {
              _myPets = petsResponse.map((p) => Pet.fromJson(p)).toList();
            }
            _error = null;
            // Re-generate greeting now that we have pet names
            _generateGreeting();
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _generateGreeting() {
    final random = Random();
    if (_petNames.isNotEmpty && random.nextDouble() > 0.55) {
      final petName = _petNames[random.nextInt(_petNames.length)];
      final dynamicOptions = [
        'Welcome back, $_firstName! How is $petName doing today?',
        '$petName hasn\'t had a check-in today 🐾',
        'Ready for some playtime with $petName? 🐶',
        '$petName is waiting for you! 🐾',
        'Time to check in on $petName today 💛',
      ];
      _currentGreeting = dynamicOptions[random.nextInt(dynamicOptions.length)];
    } else {
      _currentGreeting = _baseGreetings[random.nextInt(_baseGreetings.length)];
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
                child: Text('Add Pet', style: GoogleFonts.poppins()),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openAddPetAndSave() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddEditPetScreen()));
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
            Container(
              constraints: const BoxConstraints(minHeight: 48),
              alignment: Alignment.centerLeft,
              child: Text(
                _currentGreeting,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 12),
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
            _buildSectionTitle('My Pets'),
            const SizedBox(height: 12),
            if (_myPets.isEmpty)
              Text(
                'No pets added yet.',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            if (_myPets.isNotEmpty)
              SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _myPets.length,
                  itemBuilder: (context, index) {
                    final pet = _myPets[index];
                    final isNetworkUrl =
                        pet.photoUrl != null &&
                        (pet.photoUrl!.startsWith('http') ||
                            pet.photoUrl!.startsWith('https'));

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PetProfileScreen(pet: pet),
                          ),
                        );
                      },
                      child: Container(
                        width: 110,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundImage: isNetworkUrl
                                  ? NetworkImage(pet.photoUrl!)
                                  : const AssetImage('assets/images/logo.png')
                                        as ImageProvider,
                              backgroundColor: AppColors.background,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              pet.name ?? 'Unknown',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
                  Text(
                    address,
                    style: GoogleFonts.poppins(color: AppColors.textDark),
                  ),
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
