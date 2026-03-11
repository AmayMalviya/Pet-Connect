import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/screens/community_screen.dart';
import 'package:pet_connect_app/screens/main_screen.dart';
import 'package:pet_connect_app/screens/profile_screen.dart';
import 'package:pet_connect_app/screens/services_screen.dart';
import 'package:pet_connect_app/screens/login_screen.dart';
import 'package:pet_connect_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _userName = 'User';
  String _firstName = 'User';
  String _userEmail = '';
  String? _photoUrl;
  
  List<String> _petNames = [];
  String _currentGreeting = "Welcome back! 🐾";

  final List<String> _baseGreetings = [
    // General Welcome
    "Welcome back! Your pets are happy to see you. 🐾",
    "Hello again! Ready to check on your pets?",
    "Good to see you! Let’s care for some happy pets.",
    "Welcome back to Pet Connect!",
    "Your pet world is waiting for you.",
    // Playful
    "A wagging tail is waiting somewhere! 🐶",
    "Your furry friends say hello!",
    "Someone just wagged their tail thinking about you.",
    "Time to spread some pawsitive vibes. 🐾",
    "Your pets’ happiness starts here.",
    // Care & Health
    "Let’s keep your pets happy and healthy today.",
    "Your pets’ care journey continues.",
    "A happy pet is a healthy pet. Let’s begin.",
    "Check in on your pets today.",
    "Small care today, big happiness tomorrow.",
    // Community
    "Let’s see what the pet community is sharing today.",
    "Pet lovers are connecting right now.",
    "Your pet community is waiting.",
    "Discover stories from fellow pet parents.",
    "Let’s connect with the pet world.",
    // Adoption
    "Some pets are waiting for a loving home today.",
    "Maybe today you meet your new best friend. 🐕",
    "Every pet deserves love.",
    "Let’s help more pets find homes.",
    "Adoption stories start here.",
    // Short Minimal
    "Hello, pet parent!",
    "Welcome back. 🐾",
    "Ready for some pawsitive moments?",
    "Your pets await.",
    "Let’s begin the pet journey."
  ];

  @override
  void initState() {
    super.initState();
    // Set an initial random normal greeting in case network takes long
    _currentGreeting = _baseGreetings[Random().nextInt(_baseGreetings.length)];
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        // Fetch profile
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('first_name, last_name, email, photo_url')
            .eq('user_id', user.id)
            .maybeSingle();

        // Fetch user's pets
        final petsResponse = await Supabase.instance.client
            .from('pets')
            .select('name')
            .eq('owner_id', user.id);
            
        final fetchedPetNames = (petsResponse as List).map((p) => p['name'] as String).toList();

        if (mounted) {
          setState(() {
            _firstName = profile?['first_name'] ?? 'User';
            _userName = '${profile?['first_name'] ?? ''} ${profile?['last_name'] ?? ''}'.trim();
            _userEmail = profile?['email'] ?? user.email ?? '';
            _photoUrl = profile?['photo_url'];
            _petNames = fetchedPetNames;
            
            _generateGreeting();
          });
        }
      } catch (e) {
        debugPrint('Error loading drawer data: $e');
      }
    }
  }

  void _generateGreeting() {
    final random = Random();
    
    // Sometimes we want to use the completely dynamic ones if they have a pet
    if (_petNames.isNotEmpty && random.nextDouble() > 0.6) {
      final String randomPetName = _petNames[random.nextInt(_petNames.length)];
      final List<String> dynamicPetGreetings = [
        "Welcome back, $_firstName! How is $randomPetName doing today?",
        "$randomPetName hasn’t had a check-in today 🐾",
        "Ready for some playtime with $randomPetName?",
        "$randomPetName says hello! 🐶",
      ];
      _currentGreeting = dynamicPetGreetings[random.nextInt(dynamicPetGreetings.length)];
    } else {
      // Pick randomly from the base user-provided list
      _currentGreeting = _baseGreetings[random.nextInt(_baseGreetings.length)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Drawer(
      child: Column(
        children: [
          // Custom header replaces UserAccountsDrawerHeader to fix RenderFlex overflow
          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding: EdgeInsets.fromLTRB(16, topPadding + 20, 16, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: _photoUrl != null
                      ? NetworkImage(_photoUrl!) as ImageProvider
                      : const AssetImage('assets/images/profile_avatar.png'),
                  backgroundColor: Colors.white,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _userName.isEmpty ? 'User' : _userName,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_userEmail.isNotEmpty)
                        Text(
                          _userEmail,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: Text('Home', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pushReplacementNamed(context, MainScreen.routeName);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: Text('Community', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pushReplacementNamed(context, CommunityScreen.routeName);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.miscellaneous_services_outlined),
                  title: Text('Services', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pushReplacementNamed(context, ServicesScreen.routeName);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text('Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pushNamed(context, ProfileScreen.routeName);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: Text('Logout', style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.redAccent)),
                  onTap: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, LoginScreen.routeName, (route) => false);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
