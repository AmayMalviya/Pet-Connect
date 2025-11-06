import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/screens/shelter/manage_pets_screen.dart';
import 'package:pet_connect_app/screens/adoption_requests_screen.dart';
import 'package:pet_connect_app/screens/shelter_profile_screen.dart';
import 'package:pet_connect_app/screens/shelter/manage_appointments_screen.dart';
import 'package:pet_connect_app/screens/shelter/shelter_analytics_screen.dart';

class ShelterHomeScreen extends StatelessWidget {
  static const routeName = '/shelter-home';

  const ShelterHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome to Pet Connect!',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [Theme.of(context).primaryColor.withOpacity(0.8), Theme.of(context).primaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 45, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}