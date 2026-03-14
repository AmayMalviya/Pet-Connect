import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/screens/add_edit_pet_screen.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:pet_connect_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/screens/pet_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const String routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasPet = false;
  bool _isLoading = true;
  String? _firstName;
  String? _error;
  List<Pet> _myPets = [];
  String _currentGreeting = 'Welcome back! 🐾';

  final List<String> _baseGreetings = [
    'Welcome back! Your pets are happy to see you. 🐾',
    'Hello again! Ready to check on your pets?',
    "Good to see you! Let's care for some happy pets.",
    'Your furry friends say hello!',
    'Someone just wagged their tail thinking about you.',
    'Time to spread some pawsitive vibes. 🐾',
    "Let's keep your pets happy and healthy today.",
    'Small care today, big happiness tomorrow.',
    'Maybe today you meet your new best friend. 🐕',
    'Hello, pet parent!',
    'Welcome back. 🐾',
    'Ready for some pawsitive moments?',
  ];

  final List<String> _vetNames = [
    'Dr. Aarav Sharma',
    'Dr. Vivaan Gupta',
    'Dr. Aditya Singh',
    'Dr. Ishaan Patel',
    'Dr. Reyansh Kumar',
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
            _firstName = profile?['first_name'] ?? 'there';
            _hasPet = (petsResponse as List).isNotEmpty;
            if (_hasPet) {
              _myPets = petsResponse.map((p) => Pet.fromJson(p)).toList();
            }
            _error = null;
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
    if (_myPets.isNotEmpty && random.nextDouble() > 0.55) {
      final petName =
          _myPets[random.nextInt(_myPets.length)].name ?? 'your pet';
      final dynamicOptions = [
        'How is $petName doing today? 🐾',
        '$petName hasn\'t had a check-in today!',
        'Ready for some playtime with $petName? 🐶',
        '$petName is waiting for you! 🐾',
        'Time to check in on $petName 💛',
      ];
      _currentGreeting = dynamicOptions[random.nextInt(dynamicOptions.length)];
    } else {
      _currentGreeting = _baseGreetings[random.nextInt(_baseGreetings.length)];
    }
  }

  Future<void> _openAddPetAndSave() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddEditPetScreen()));
    if (result == true && mounted) {
      setState(() => _hasPet = true);
      await _loadUserData();
    }
  }

  void _showAddPetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
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
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Later',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text('Error: $_error', style: GoogleFonts.poppins()),
      );
    }
    return _buildBody();
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero banner ─────────────────────────────────────────────────
          _buildHeroBanner(),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Search ───────────────────────────────────────────────
                _buildSearchBar(),
                const SizedBox(height: 20),

                // ── Add pet prompt ───────────────────────────────────────
                if (!_hasPet) ...[
                  _buildAddPetBanner(),
                  const SizedBox(height: 20),
                ],

                // ── My Pets ──────────────────────────────────────────────
                if (_myPets.isNotEmpty) ...[
                  _buildSectionTitle('My Pets'),
                  const SizedBox(height: 12),
                  _buildPetsRow(),
                  const SizedBox(height: 20),
                ],

                // ── Nearby Vets ──────────────────────────────────────────
                _buildSectionTitle('Nearby Vets'),
                const SizedBox(height: 10),
                _buildVetList(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Banner ───────────────────────────────────────────────────────────
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _firstName != null ? 'Hi, $_firstName 👋' : 'Hi there 👋',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _currentGreeting,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pets, color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'Search for services, products...',
          hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ── Add Pet Banner ────────────────────────────────────────────────────────
  Widget _buildAddPetBanner() {
    return GestureDetector(
      onTap: _openAddPetAndSave,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.primary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.pets, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Your First Pet',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Add a pet to unlock all features',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  // ── Section Title ─────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  // ── Pets Row ──────────────────────────────────────────────────────────────
  Widget _buildPetsRow() {
    return SizedBox(
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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PetProfileScreen(pet: pet)),
            ),
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
    );
  }

  // ── Vet List ──────────────────────────────────────────────────────────────
  Widget _buildVetList() {
    final random = Random();
    return Column(
      children: List.generate(3, (index) {
        return VetCard(
          name: _vetNames[random.nextInt(_vetNames.length)],
          address: '123 Main Street, Anytown, USA',
          rating: 4.5,
        );
      }),
    );
  }
}

// ── Vet Card ──────────────────────────────────────────────────────────────────

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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_hospital_outlined,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: GoogleFonts.poppins(
                    color: AppColors.textDark,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Open Now',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Rating + Book
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: AppColors.primary, size: 18),
                  Text(
                    rating.toString(),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Book',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
