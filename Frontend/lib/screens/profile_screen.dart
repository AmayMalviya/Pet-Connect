import 'package:flutter/material.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:pet_connect_app/screens/add_pet_screen.dart';
import 'package:pet_connect_app/screens/pet_profile_screen.dart';
import '../models/profile_args.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final List<Pet> _pets = [
    Pet(name: 'Buddy', breed: 'Golden Retriever', imageUrl: 'assets/images/logo.png'),
    Pet(name: 'Lucy', breed: 'Labrador', imageUrl: 'assets/images/logo.png'),
  ];

  void _addPet(Pet pet) {
    setState(() {
      _pets.add(pet);
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as ProfileArgs?;
    final name = args?.name ?? "Guest";
    final email = args?.email ?? "guest@example.com";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Profile"),
        actions: [
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildProfileHeader(name, email),
          const SizedBox(height: 20),
          _buildPetList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newPet = await Navigator.of(context).pushNamed(AddPetScreen.routeName);
          if (newPet != null && newPet is Pet) {
            _addPet(newPet);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProfileHeader(String name, String email) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 40,
          backgroundImage: AssetImage('assets/images/logo.png'), // Add user image
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(email),
          ],
        ),
      ],
    );
  }

  Widget _buildPetList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Pets',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _pets.length,
          itemBuilder: (context, index) {
            final pet = _pets[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: AssetImage(pet.imageUrl),
                ),
                title: Text(pet.name),
                subtitle: Text(pet.breed),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PetProfileScreen(pet: pet),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
