import 'package:flutter/material.dart';

class GroomingDetailsScreen extends StatelessWidget {
  static const String routeName = '/grooming-details';

  const GroomingDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grooming Details'),
        leading: const BackButton(), // Added back button
      ),
      body: const Center(
        child: Text(
          'Details about Grooming services.',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}