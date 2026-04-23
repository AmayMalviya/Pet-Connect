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
import 'package:pet_connect_app/widgets/kyc_status_banner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Shelter Screens
import 'package:pet_connect_app/screens/shelter_home_screen.dart';
import 'package:pet_connect_app/screens/shelter/manage_pets_screen.dart';
import 'package:pet_connect_app/screens/shelter_adoption_requests_screen.dart';

// Vet Screens
import 'package:pet_connect_app/screens/vet_home_screen.dart';
import 'package:pet_connect_app/screens/appointments_screen.dart';
import 'package:pet_connect_app/screens/my_patients_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static const String routeName = '/main';

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String? _photoUrl;
  String _userRole = 'Pet Owner';
  bool _kycVerified = false;
  bool _isLoadingRole = true;

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
          .select('photo_url, role, kyc_verified')
          .eq('user_id', user.id)
          .maybeSingle();
      if (profile != null) {
        setState(() {
          _photoUrl = profile['photo_url'];
          _userRole = profile['role'] ?? 'Pet Owner';
          _kycVerified = profile['kyc_verified'] == true;
          _isLoadingRole = false;
        });
      }
    }
  }

  List<Widget> _getWidgetOptions() {
    switch (_userRole) {
      case 'Admin':
        return [
          const HomeScreen(), // Admin Dashboard fallback or specific admin home
          const ServicesScreen(),
          const CommunityScreen(),
        ];
      case 'Shelter':
      case 'Shelter Owner':
        return [
          const ShelterHomeScreen(),
          const ManagePetsScreen(),
          const ShelterAdoptionRequestsScreen(),
          const CommunityScreen(),
        ];
      case 'Vet':
        return [
          const VetHomeScreen(),
          const MyPatientsScreen(),
          const AppointmentsScreen(),
          const CommunityScreen(),
        ];
      default:
        return [
          const HomeScreen(),
          const ServicesScreen(),
          const ShopScreen(),
          const CommunityScreen(),
        ];
    }
  }

  List<String> _getAppBarTitles() {
    switch (_userRole) {
      case 'Shelter':
      case 'Shelter Owner':
        return ['Shelter Home', 'Manage Pets', 'Adoptions', 'Community'];
      case 'Vet':
        return ['Vet Dashboard', 'My Patients', 'Appointments', 'Community'];
      default:
        return ['Home', 'Services', 'Shop', 'Community'];
    }
  }

  List<BottomNavigationBarItem> _getBottomNavItems() {
    switch (_userRole) {
      case 'Shelter':
      case 'Shelter Owner':
        return [
          const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Pets'),
          const BottomNavigationBarItem(icon: Icon(Icons.volunteer_activism), label: 'Requests'),
          const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Community'),
        ];
      case 'Vet':
        return [
          const BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.assignment_ind), label: 'Patients'),
          const BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Appts'),
          const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Community'),
        ];
      default:
        return [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: 'Services'),
          const BottomNavigationBarItem(icon: Icon(Icons.shop), label: 'Shop'),
          const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Community'),
        ];
    }
  }  // end of _getBottomNavItems()

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final widgetOptions = _getWidgetOptions();
    final appBarTitles = _getAppBarTitles();
    final bottomNavItems = _getBottomNavItems();

    // Show persistent KYC banner for shelters that are not verified
    bool showKycBanner = (_userRole == 'Shelter' || _userRole == 'Shelter Owner') && !_kycVerified;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appBarTitles[_selectedIndex],
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
      drawer: const AppDrawer(),
      body: Column(
        children: [
          if (showKycBanner) const KycStatusBanner(),
          Expanded(
            child: widgetOptions.elementAt(_selectedIndex),
          ),
        ],
      ),
      floatingActionButton: (_selectedIndex == 0 || _selectedIndex == 1)
          ? FloatingActionButton.extended(
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
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        items: bottomNavItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: AppColors.textDark.withOpacity(0.5),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
      ),
    );
  }
}
