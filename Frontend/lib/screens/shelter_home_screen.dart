import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/screens/manage_pets_screen.dart';
import 'package:pet_connect_app/screens/adoption_requests_screen.dart';
import 'package:pet_connect_app/screens/shelter_profile_screen.dart';

class ShelterHomeScreen extends StatelessWidget {
  static const routeName = '/shelter-home';

  const ShelterHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shelter Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
  backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome, Shelter Owner!',
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
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
            Icon(icon, size: 40, color: Theme.of(context).primaryColor),
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