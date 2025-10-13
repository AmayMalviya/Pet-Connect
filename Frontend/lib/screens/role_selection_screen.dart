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

  Future<void> _submitRole() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // If user is null, wait for the auth state to change.
        // This can happen if the user has just registered and the user object is not yet available.
        user = await FirebaseAuth.instance.authStateChanges().first;
      }

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'role': _selectedRole}, SetOptions(merge: true));

        if (!mounted) return;

        if (_selectedRole == 'Pet Owner') {
          Navigator.of(context).pushReplacementNamed(MainScreen.routeName);
        } else {
          Navigator.of(context)
              .pushReplacementNamed(KycScreen.routeName, arguments: _selectedRole);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication error. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select role: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'How will you be using Pet Connect?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your primary role to get a personalized experience.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 48),
              _buildRoleCard(
                context,
                title: 'Pet Owner',
                description: 'For those looking to adopt or connect with other pet lovers.',
                icon: Icons.person_outline,
                onTap: () => setState(() => _selectedRole = 'Pet Owner'),
                isSelected: _selectedRole == 'Pet Owner',
              ),
              const SizedBox(height: 24),
              _buildRoleCard(
                context,
                title: 'Shelter Owner',
                description: 'Manage a shelter, list pets for adoption, and connect with potential adopters.',
                icon: Icons.home_outlined,
                onTap: () => setState(() => _selectedRole = 'Shelter Owner'),
                isSelected: _selectedRole == 'Shelter Owner',
              ),
              const SizedBox(height: 24),
              _buildRoleCard(
                context,
                title: 'Vet',
                description: 'Provide veterinary services and connect with pet owners.',
                icon: Icons.medical_services_outlined,
                onTap: () => setState(() => _selectedRole = 'Vet'),
                isSelected: _selectedRole == 'Vet',
              ),
              const Spacer(),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _selectedRole == null ? null : _submitRole,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Continue', style: TextStyle(fontSize: 18)),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isSelected ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700]),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
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
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}