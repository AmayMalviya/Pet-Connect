import 'package:flutter/material.dart';

class MyPatientsScreen extends StatelessWidget {
  static const routeName = '/vet-my-patients';

  const MyPatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Patients'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0), // Added padding
        itemCount: 15, // Example count
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
                'Buddy ${index + 1}', // More descriptive pet name
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Owner: John Doe ${index + 1} - Breed: Golden Retriever'), // More descriptive owner/breed
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Navigate to patient details screen
              },
            ),
          );
        },
      ),
    );
  }
}
