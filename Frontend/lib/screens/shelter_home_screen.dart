import 'package:flutter/material.dart';
import 'package:pet_connect_app/screens/shelter/shelter_pets_screen.dart';
import 'package:pet_connect_app/screens/shelter/adoption_requests_screen.dart';
import 'package:pet_connect_app/screens/add_pet_screen.dart'; // Reusing existing screen
import 'package:pet_connect_app/screens/shelter/shelter_profile_screen.dart';

class ShelterHomeScreen extends StatelessWidget {
  static const routeName = '/shelter-home';

  const ShelterHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shelter Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // TODO: Implement logout
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0), // Increased padding
        children: [
          Text(
            'Welcome, Shelter Owner!', // Added welcome message
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildDashboardCard(
            context,
            title: 'Pets in Shelter',
            icon: Icons.pets,
            onTap: () {
              Navigator.pushNamed(context, ShelterPetsScreen.routeName);
            },
          ),
          const SizedBox(height: 20), // Adjusted spacing
          _buildDashboardCard(
            context,
            title: 'Adoption Requests',
            icon: Icons.inbox,
            onTap: () {
              Navigator.pushNamed(context, AdoptionRequestsScreen.routeName);
            },
          ),
          const SizedBox(height: 20), // Adjusted spacing
          _buildDashboardCard(
            context,
            title: 'Add New Pet',
            icon: Icons.add,
            onTap: () {
              Navigator.pushNamed(context, AddPetScreen.routeName);
            },
          ),
          const SizedBox(height: 20), // Adjusted spacing
          _buildDashboardCard(
            context,
            title: 'Manage Profile',
            icon: Icons.store,
            onTap: () {
              Navigator.pushNamed(context, ShelterProfileScreen.routeName);
            },
          ),
        ],
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
