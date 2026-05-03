import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/screens/community_screen.dart';
import 'package:pet_connect_app/screens/main_screen.dart';
import 'package:pet_connect_app/screens/profile_screen.dart';
import 'package:pet_connect_app/screens/services_screen.dart';
import 'package:pet_connect_app/screens/shop_screen.dart';
import 'package:pet_connect_app/screens/login_screen.dart';
import 'package:pet_connect_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Shelter Screens
import 'package:pet_connect_app/screens/shelter_home_screen.dart';
import 'package:pet_connect_app/screens/shelter/manage_pets_screen.dart';
import 'package:pet_connect_app/screens/shelter_adoption_requests_screen.dart';
import 'package:pet_connect_app/screens/shelter/shelter_analytics_screen.dart';
import 'package:pet_connect_app/screens/shelter_profile_screen.dart';

// Admin Screens
import 'package:pet_connect_app/screens/admin/admin_dashboard_screen.dart';
import 'package:pet_connect_app/screens/admin/manage_profiles_screen.dart';
import 'package:pet_connect_app/screens/admin/admin_kyc_approval_screen.dart';
import 'package:pet_connect_app/screens/admin/manage_community_screen.dart';
import 'package:pet_connect_app/screens/admin/admin_analytics_screen.dart';

// Vet Screens
import 'package:pet_connect_app/screens/vet_home_screen.dart';
import 'package:pet_connect_app/screens/my_patients_screen.dart';
import 'package:pet_connect_app/screens/appointments_screen.dart';
import 'package:pet_connect_app/screens/vet_profile_screen.dart';

class AppDrawer extends StatefulWidget {
  /// Called with the tab index to switch to in MainScreen.
  /// Pass null-safe — drawer items that open a new screen use pushNamed directly.
  final void Function(int index)? onTabSwitch;
  const AppDrawer({super.key, this.onTabSwitch});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _userName = 'User';
  String _firstName = 'User';
  String _userEmail = '';
  String? _photoUrl;
  String _userRole = 'Pet Owner';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        // Fetch profile
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('first_name, last_name, email, photo_url, role')
            .eq('user_id', user.id)
            .maybeSingle();

        if (mounted) {
          setState(() {
            _firstName = profile?['first_name'] ?? 'User';
            _userName = '${profile?['first_name'] ?? ''} ${profile?['last_name'] ?? ''}'.trim();
            _userEmail = profile?['email'] ?? user.email ?? '';
            _photoUrl = profile?['photo_url'];
            _userRole = profile?['role'] ?? 'Pet Owner';
          });
        }

      } catch (e) {
        debugPrint('Error loading drawer data: $e');
      }
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
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _userRole.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
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
                if (_userRole == 'Admin') ..._buildAdminItems()
                else if (_userRole == 'Shelter' || _userRole == 'Shelter Owner') ..._buildShelterItems()
                else if (_userRole == 'Vet') ..._buildVetItems()
                else ..._buildPetOwnerItems(),
                
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  color: Colors.redAccent,
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
  }  // end of build()

  List<Widget> _buildPetOwnerItems() {
    return [
      _buildDrawerItem(
        icon: Icons.home_outlined,
        title: 'Home',
        onTap: () { Navigator.pop(context); widget.onTabSwitch?.call(0); },
      ),
      _buildDrawerItem(
        icon: Icons.miscellaneous_services_outlined,
        title: 'Services',
        onTap: () { Navigator.pop(context); widget.onTabSwitch?.call(1); },
      ),
      _buildDrawerItem(
        icon: Icons.shopping_bag_outlined,
        title: 'Shop',
        onTap: () { Navigator.pop(context); widget.onTabSwitch?.call(2); },
      ),
      _buildDrawerItem(
        icon: Icons.people_outline,
        title: 'Community',
        onTap: () { Navigator.pop(context); widget.onTabSwitch?.call(3); },
      ),
      _buildDrawerItem(
        icon: Icons.person_outline,
        title: 'Profile',
        onTap: () { Navigator.pop(context); Navigator.pushNamed(context, ProfileScreen.routeName); },
      ),
    ];
  }

  List<Widget> _buildShelterItems() {
    return [
      _buildDrawerItem(
        icon: Icons.dashboard_outlined,
        title: 'Shelter Hub',
        onTap: () { Navigator.pop(context); widget.onTabSwitch?.call(0); },
      ),
      _buildDrawerItem(
        icon: Icons.pets_outlined,
        title: 'Manage Pets',
        onTap: () { Navigator.pop(context); widget.onTabSwitch?.call(1); },
      ),
      _buildDrawerItem(
        icon: Icons.volunteer_activism_outlined,
        title: 'Adoption Requests',
        onTap: () { Navigator.pop(context); widget.onTabSwitch?.call(2); },
      ),
      _buildDrawerItem(
        icon: Icons.analytics_outlined,
        title: 'Analytics',
        onTap: () { Navigator.pop(context); Navigator.pushNamed(context, ShelterAnalyticsScreen.routeName); },
      ),
      _buildDrawerItem(
        icon: Icons.person_outline,
        title: 'Shelter Profile',
        onTap: () { Navigator.pop(context); Navigator.pushNamed(context, ShelterProfileScreen.routeName); },
      ),
    ];
  }

  List<Widget> _buildAdminItems() {
    return [
      _buildDrawerItem(
        icon: Icons.admin_panel_settings_outlined,
        title: 'Admin Dashboard',
        onTap: () => Navigator.pushReplacementNamed(context, AdminDashboardScreen.routeName),
      ),
      _buildDrawerItem(
        icon: Icons.people_alt_outlined,
        title: 'Manage Profiles',
        onTap: () => Navigator.pushNamed(context, ManageProfilesScreen.routeName),
      ),
      _buildDrawerItem(
        icon: Icons.verified_user_outlined,
        title: 'KYC Approvals',
        onTap: () => Navigator.pushNamed(context, AdminKycApprovalScreen.routeName),
      ),
      _buildDrawerItem(
        icon: Icons.groups_outlined,
        title: 'Manage Community',
        onTap: () => Navigator.pushNamed(context, ManageCommunityScreen.routeName),
      ),
      _buildDrawerItem(
        icon: Icons.bar_chart_outlined,
        title: 'App Analytics',
        onTap: () => Navigator.pushNamed(context, AdminAnalyticsScreen.routeName),
      ),
    ];
  }

  List<Widget> _buildVetItems() {
    return [
      _buildDrawerItem(
        icon: Icons.medical_services_outlined,
        title: 'Vet Dashboard',
        onTap: () { Navigator.pop(context); widget.onTabSwitch?.call(0); },
      ),
      _buildDrawerItem(
        icon: Icons.assignment_ind_outlined,
        title: 'My Patients',
        onTap: () { Navigator.pop(context); widget.onTabSwitch?.call(1); },
      ),
      _buildDrawerItem(
        icon: Icons.calendar_today_outlined,
        title: 'Appointments',
        onTap: () { Navigator.pop(context); widget.onTabSwitch?.call(2); },
      ),
      _buildDrawerItem(
        icon: Icons.person_outline,
        title: 'Vet Profile',
        onTap: () { Navigator.pop(context); Navigator.pushNamed(context, VetProfileScreen.routeName); },
      ),
    ];
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textDark, size: 24),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 15,
          color: color ?? AppColors.textDark,
        ),
      ),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }
}
