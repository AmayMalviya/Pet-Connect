import 'package:flutter/material.dart';
import 'package:pet_connect_app/screens/main_screen.dart';
import 'package:pet_connect_app/screens/kyc_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleSelectionScreen extends StatelessWidget {
  static const routeName = '/role-selection';

  const RoleSelectionScreen({super.key});

  Future<void> _selectRole(BuildContext context, String role) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({'role': role});
      if (role == 'Pet Owner') {
        Navigator.of(context).pushReplacementNamed(MainScreen.routeName);
      } else {
        Navigator.of(context).pushReplacementNamed(KycScreen.routeName, arguments: role);
      }
    }
  }

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
              onTap: () => _selectRole(context, 'Pet Owner'),
            ),
            const SizedBox(height: 24), // Adjusted spacing
            _buildRoleCard(
              context,
              title: 'Shelter Owner',
              icon: Icons.home,
              onTap: () => _selectRole(context, 'Shelter Owner'),
            ),
            const SizedBox(height: 24), // Adjusted spacing
            _buildRoleCard(
              context,
              title: 'Vet',
              icon: Icons.medical_services,
              onTap: () => _selectRole(context, 'Vet'),
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