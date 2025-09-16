import 'package:flutter/material.dart';
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
        title: const Text('Vet Dashboard'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome, Doctor!', // Added welcome message
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildDashboardCard(
              context,
              title: 'Appointments',
              icon: Icons.calendar_today,
              onTap: () {
                Navigator.pushNamed(context, AppointmentsScreen.routeName);
              },
            ),
            const SizedBox(height: 20), // Adjusted spacing
            _buildDashboardCard(
              context,
              title: 'My Patients',
              icon: Icons.pets,
              onTap: () {
                Navigator.pushNamed(context, MyPatientsScreen.routeName);
              },
            ),
            const SizedBox(height: 20), // Adjusted spacing
            _buildDashboardCard(
              context,
              title: 'Scan Pet QR',
              icon: Icons.qr_code_scanner,
              onTap: () {
                Navigator.pushNamed(context, ScanPetQrScreen.routeName);
              },
            ),
            const SizedBox(height: 20), // Adjusted spacing
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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Theme.of(context).primaryColor),
              const SizedBox(width: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}