import 'package:flutter/material.dart';
import 'package:pet_connect_app/screens/shelter_verification_screen.dart';
import 'package:pet_connect_app/screens/main_screen.dart';
import 'package:pet_connect_app/screens/kyc_screen.dart';
import 'package:pet_connect_app/screens/profile_setup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/utils/role_helpers.dart';

class RoleSelectionScreen extends StatefulWidget {
  static const routeName = '/role-selection';

  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _isLoading = true;
  String? _selectedRoleId;
  List<Map<String, dynamic>> _roles = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRoles();
  }

  Future<void> _fetchRoles() async {
    try {
      final response = await Supabase.instance.client.from('roles').select('id, name');
      setState(() {
        _roles = (response as List).map((role) => {'id': role['id'], 'name': role['name']}).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load roles: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _getRoleDescription(String roleName) {
    switch (roleName) {
      case 'Pet Owner':
        return 'Manage your pets, appointments, and connect with a community of pet lovers.';
      case 'Shelter Owner':
        return 'Manage your shelter, list pets for adoption, and connect with potential adopters.';
      default:
        return 'A general user role.';
    }
  }

  Future<void> _submitRole() async {
    if (_selectedRoleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final selectedRole = _roles.firstWhere((role) => role['id'] == _selectedRoleId);

        await Supabase.instance.client.from('profiles').upsert({
          'user_id': user.id,
          'role': selectedRole['name'],
        });

        if (!mounted) return;

        if (selectedRole['name'] == 'Pet Owner') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileSetupScreen(role: 'Pet Owner'),
            ),
          );
        } else if (selectedRole['name'] == 'Shelter') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileSetupScreen(role: 'Shelter'),
            ),
          );
        } else {
          Navigator.pushReplacementNamed(
            context,
            KycScreen.routeName,
            arguments: selectedRole['name'],
          );
        }
      } else {
        throw Exception('User is not logged in');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save role: ${e.toString()}')),
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : _roles.isEmpty
                      ? const Center(child: Text('No roles available. Please contact support.'))
                      : Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
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
                                    ..._roles.map((role) {
                                      final roleName = role['name'] as String;
                                      final description = _getRoleDescription(roleName);
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 24.0),
                                        child: _buildRoleCard(
                                          context,
                                          title: roleName,
                                          description: description,
                                          icon: getIconForRole(roleName),
                                          onTap: () => setState(() => _selectedRoleId = role['id']),
                                          isSelected: _selectedRoleId == role['id'],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _selectedRoleId == null || _isLoading ? null : _submitRole,
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