import 'package:flutter/material.dart';
import 'package:pet_connect_app/screens/main_screen.dart';
import 'package:pet_connect_app/screens/kyc_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  static const routeName = '/role-selection';

  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Role'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0), // Increased padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRoleCard(
              context,
              title: 'Pet Owner',
              icon: Icons.person,
              onTap: () {
                Navigator.of(context).pushReplacementNamed(MainScreen.routeName);
              },
            ),
            const SizedBox(height: 24), // Adjusted spacing
            _buildRoleCard(
              context,
              title: 'Shelter Owner',
              icon: Icons.home,
              onTap: () {
                Navigator.of(context).pushReplacementNamed(KycScreen.routeName, arguments: 'Shelter Owner');
              },
            ),
            const SizedBox(height: 24), // Adjusted spacing
            _buildRoleCard(
              context,
              title: 'Vet',
              icon: Icons.medical_services,
              onTap: () {
                Navigator.of(context).pushReplacementNamed(KycScreen.routeName, arguments: 'Vet');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
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