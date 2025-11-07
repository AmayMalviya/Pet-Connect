import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/screens/profile_details_screen.dart';

class ManageProfilesScreen extends StatefulWidget {
  static const routeName = '/manage-profiles';

  const ManageProfilesScreen({super.key});

  @override
  State<ManageProfilesScreen> createState() => _ManageProfilesScreenState();
}

class _ManageProfilesScreenState extends State<ManageProfilesScreen> {
  late Future<List<Map<String, dynamic>>> _profilesFuture;

  @override
  void initState() {
    super.initState();
    _profilesFuture = _fetchProfiles();
  }

  Future<List<Map<String, dynamic>>> _fetchProfiles() async {
    final supabase = Supabase.instance.client;
    final response = await supabase.from('profiles').select('*');
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Profiles'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _profilesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No profiles found.'));
          }

          final profiles = snapshot.data!;

          return ListView.builder(
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              final fullName = '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim();
              final role = profile['role'] ?? 'N/A';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(fullName.isNotEmpty ? fullName : 'User ID: ${profile['user_id']}'),
                  subtitle: Text('Role: $role'),
                  onTap: () {
                    // Navigate to ProfileDetailsScreen with the profile data
                    Navigator.pushNamed(
                      context,
                      ProfileDetailsScreen.routeName,
                      arguments: profile, // Pass the entire profile map
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
