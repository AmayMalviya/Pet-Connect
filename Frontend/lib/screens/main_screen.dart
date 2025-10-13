import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/screens/community_screen.dart';
import 'package:pet_connect_app/screens/home_screen.dart';
import 'package:pet_connect_app/screens/services_screen.dart';
import 'package:pet_connect_app/screens/shop_screen.dart';
import 'package:pet_connect_app/theme/app_theme.dart';
import 'package:pet_connect_app/widgets/app_drawer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static const String routeName = '/main';

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

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
        title: Text(_appBarTitles[_selectedIndex], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // TODO: Implement notification functionality
            },
          ),
          IconButton(
            icon: const CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage('assets/images/profile_avatar.png'),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
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
