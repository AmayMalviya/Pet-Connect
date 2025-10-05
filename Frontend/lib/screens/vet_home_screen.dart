import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/screens/appointments_screen.dart';
import 'package:pet_connect_app/screens/my_patients_screen.dart';
import 'package:pet_connect_app/screens/scan_pet_qr_screen.dart';
import 'package:pet_connect_app/screens/vet_profile_screen.dart';

class VetHomeScreen extends StatelessWidget {
  static const routeName = '/vet-home';

  const VetHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vet Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome, Doctor!',
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
                    title: 'Appointments',
                    icon: Icons.calendar_today,
                    onTap: () {
                      Navigator.pushNamed(context, AppointmentsScreen.routeName);
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'My Patients',
                    icon: Icons.pets,
                    onTap: () {
                      Navigator.pushNamed(context, MyPatientsScreen.routeName);
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Scan Pet QR',
                    icon: Icons.qr_code_scanner,
                    onTap: () {
                      Navigator.pushNamed(context, ScanPetQrScreen.routeName);
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Manage Profile',
                    icon: Icons.person,
                    onTap: () {
                      Navigator.pushNamed(context, VetProfileScreen.routeName);
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