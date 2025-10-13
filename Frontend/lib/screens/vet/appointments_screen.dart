import 'package:flutter/material.dart';

class AppointmentsScreen extends StatelessWidget {
  static const routeName = '/vet-appointments';

  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0), // Added padding
        itemCount: 10, // Example count
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Adjusted margin
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                'Appointment with Sparky - ${DateTime.now().add(Duration(days: index)).day}/${DateTime.now().add(Duration(days: index)).month}', // More descriptive title
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Time: ${DateTime.now().add(Duration(days: index)).hour}:${DateTime.now().add(Duration(days: index)).minute}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Navigate to appointment details screen
              },
            ),
          );
        },
      ),
    );
  }
}
