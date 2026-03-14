import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/screens/community_screen.dart';
import 'package:pet_connect_app/screens/home_screen.dart';
import 'package:pet_connect_app/screens/services_screen.dart';
import 'package:pet_connect_app/screens/shop_screen.dart';
import 'package:pet_connect_app/theme/app_theme.dart' show AppColors;
import 'package:pet_connect_app/widgets/app_drawer.dart';
import 'package:pet_connect_app/widgets/notification_bell.dart';
import 'package:pet_connect_app/screens/global_ai_chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static const String routeName = '/main';

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('photo_url')
          .eq('user_id', user.id)
          .maybeSingle();
      if (profile != null && profile['photo_url'] != null) {
        setState(() {
          _photoUrl = profile['photo_url'];
        });
      }
    }
  }

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    ServicesScreen(),
    ShopScreen(),
    CommunityScreen(),
  ];

  static const List<String> _appBarTitles = <String>[
    'Home',
    'Services',
    'Shop',
    'Community',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _appBarTitles[_selectedIndex],
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 1,
        actions: [
          const NotificationBell(),
          IconButton(
            icon: CircleAvatar(
              radius: 18,
              backgroundImage: _photoUrl != null
                  ? NetworkImage(_photoUrl!)
                  : const AssetImage('assets/images/profile_avatar.png')
                        as ImageProvider,
            ),
            onPressed: () async {
              await Navigator.pushNamed(context, '/profile');
              _loadUserData();
            },
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'main_screen_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GlobalAIChatScreen()),
          );
        },
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Pet AI'),
        backgroundColor: AppColors.primary,
        tooltip: 'Chat with Pet AI Assistant',
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Services',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.shop), label: 'Shop'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Community'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: AppColors.textDark.withOpacity(0.5),
        onTap: _onItemTapped,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(),
      ),
    );
  }
}
