import 'package:flutter/material.dart';
import 'package:pet_connect_app/screens/main_screen.dart';
import 'package:pet_connect_app/screens/kyc_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        // Get the selected role object from cached roles
        final selectedRole = _roles.firstWhere((role) => role['id'] == _selectedRoleId);

        // Upsert the profile with the selected role_id
        await Supabase.instance.client.from('profiles').upsert({
          'user_id': user.id,
          'role_id': selectedRole['id'],
        });

        if (!mounted) return;

        // Navigate based on the selected role name
        if (selectedRole['name'] == 'Pet Owner') {
          Navigator.pushReplacementNamed(context, MainScreen.routeName);
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
                  : Column(
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
                          final description = (role['description'] != null && (role['description'] as String).trim().isNotEmpty)
                              ? role['description'] as String
                              : 'Description for ${role['name']}';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: _buildRoleCard(
                              context,
                              title: role['name'],
                              description: description,
                              icon: getIconForRole(role['name']),
                              onTap: () => setState(() => _selectedRoleId = role['id']),
                              isSelected: _selectedRoleId == role['id'],
                            ),
                          );
                        }),
                        const Spacer(),
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

  IconData _getIconForRole(String roleName) {
    switch (roleName) {
      case 'Pet Owner':
        return Icons.person_outline;
      case 'Shelter Owner':
        return Icons.home_outlined;
      case 'Vet':
        return Icons.medical_services_outlined;
      default:
        return Icons.person;
    }
  }

// Public helper so it can be unit-tested.
IconData getIconForRole(String roleName) {
  switch (roleName) {
    case 'Pet Owner':
      return Icons.person_outline;
    case 'Shelter Owner':
      return Icons.home_outlined;
    case 'Vet':
      return Icons.medical_services_outlined;
    default:
      return Icons.person;
  }
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
