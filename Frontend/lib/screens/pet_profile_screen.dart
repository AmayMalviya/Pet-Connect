import 'package:flutter/material.dart';
import 'package:pet_connect_app/models/pet.dart';

class PetProfileScreen extends StatelessWidget {
  const PetProfileScreen({super.key, required this.pet});

  final Pet pet;

  static const String routeName = '/pet-profile';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pet.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Implement edit functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // TODO: Implement delete functionality
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(radius: 80, backgroundImage: AssetImage('assets/images/logo.png')),
            const SizedBox(height: 20),
            Text(
              pet.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(pet.breed, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
