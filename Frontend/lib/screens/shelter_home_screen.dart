import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/screens/shelter/manage_pets_screen.dart';
import 'package:pet_connect_app/screens/adoption_requests_screen.dart';
import 'package:pet_connect_app/screens/shelter_profile_screen.dart';
import 'package:pet_connect_app/screens/shelter/manage_appointments_screen.dart';
import 'package:pet_connect_app/screens/shelter/shelter_analytics_screen.dart';
import 'package:pet_connect_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShelterHomeScreen extends StatefulWidget {
  static const routeName = '/shelter-home';

  const ShelterHomeScreen({super.key});

  @override
  State<ShelterHomeScreen> createState() => _ShelterHomeScreenState();
}

class _ShelterHomeScreenState extends State<ShelterHomeScreen> {
  String? _shelterName;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadShelterData();
  }

  Future<void> _loadShelterData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await Supabase.instance.client
          .from('profiles')
          .select('first_name')
          .eq('user_id', user.id)
          .maybeSingle();
        
        setState(() {
          _shelterName = (profile != null && profile['first_name'] != null)
            ? profile['first_name']
            : 'Shelter';
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(child: Text('Error: $_error')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Shelter Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getGreeting()}, ${_shelterName ?? 'Shelter'}!',
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildDashboardCard(
                  context,
                  title: 'Manage Pets',
                  icon: Icons.pets,
                  onTap: () {
                    Navigator.pushNamed(context, ManagePetsScreen.routeName);
                  },
                ),
                _buildDashboardCard(
                  context,
                  title: 'Adoption Requests',
                  icon: Icons.inbox,
                  onTap: () {
                    Navigator.pushNamed(context, AdoptionRequestsScreen.routeName);
                  },
                ),
                _buildDashboardCard(
                  context,
                  title: 'Manage Profile',
                  icon: Icons.person,
                  onTap: () {
                    Navigator.pushNamed(context, ShelterProfileScreen.routeName);
                  },
                ),
                _buildDashboardCard(
                  context,
                  title: 'Manage Appointments',
                  icon: Icons.calendar_today,
                  onTap: () {
                    Navigator.pushNamed(context, ManageAppointmentsScreen.routeName);
                  },
                ),
                _buildDashboardCard(
                  context,
                  title: 'Shelter Analytics',
                  icon: Icons.analytics,
                  onTap: () {
                    Navigator.pushNamed(context, ShelterAnalyticsScreen.routeName);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: AppColors.primary),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}