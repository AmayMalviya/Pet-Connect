import 'package:flutter/material.dart';
import 'package:pet_connect_app/screens/main_screen.dart';
import 'package:pet_connect_app/screens/kyc_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleSelectionScreen extends StatefulWidget {
  static const routeName = '/role-selection';

  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _isLoading = false;
  String? _selectedRole;

  Future<void> _selectRole(BuildContext context, String role) async {
    setState(() {
      _isLoading = true;
      _selectedRole = role;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'role': role}, SetOptions(merge: true));

        if (role == 'Pet Owner') {
          Navigator.of(context).pushReplacementNamed(MainScreen.routeName);
        } else {
          Navigator.of(context)
              .pushReplacementNamed(KycScreen.routeName, arguments: role);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select role: ${e.toString()}')),
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedRole = null;
        });
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRoleCard(
              context,
              title: 'Pet Owner',
              description: 'For those looking to adopt or connect with other pet lovers.',
              icon: Icons.person,
              onTap: () => _selectRole(context, 'Pet Owner'),
              isLoading: _isLoading && _selectedRole == 'Pet Owner',
            ),
            const SizedBox(height: 24),
            _buildRoleCard(
              context,
              title: 'Shelter Owner',
              description: 'Manage a shelter, list pets for adoption, and connect with potential adopters.',
              icon: Icons.home,
              onTap: () => _selectRole(context, 'Shelter Owner'),
              isLoading: _isLoading && _selectedRole == 'Shelter Owner',
            ),
            const SizedBox(height: 24),
            _buildRoleCard(
              context,
              title: 'Vet',
              description: 'Provide veterinary services and connect with pet owners.',
              icon: Icons.medical_services,
              onTap: () => _selectRole(context, 'Vet'),
              isLoading: _isLoading && _selectedRole == 'Vet',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Theme.of(context).primaryColor),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}