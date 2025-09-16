import 'package:flutter/material.dart';

class ShelterPetsScreen extends StatelessWidget {
  static const routeName = '/shelter-pets';

  const ShelterPetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pets in Shelter'),
        leading: const BackButton(), // Added back button
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0), // Added padding
        itemCount: 20, // Example count
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Adjusted margin
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                child: Icon(Icons.pets, color: Theme.of(context).primaryColor),
              ),
              title: Text(
                'Whiskers ${index + 1}', // More descriptive pet name
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Breed: Domestic Shorthair - Status: Available for adoption'), // More descriptive status
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Navigate to pet details screen
              },
            ),
          );
        },
      ),
    );
  }
}
