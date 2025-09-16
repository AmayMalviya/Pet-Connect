import 'package:flutter/material.dart';

class TrainingDetailsScreen extends StatelessWidget {
  static const String routeName = '/training-details';

  const TrainingDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Details'),
        leading: const BackButton(), // Added back button
      ),
      body: const Center(
        child: Text(
          'Details about Training services.',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}