import 'package:flutter/material.dart';

class VetDetailsScreen extends StatelessWidget {
  static const String routeName = '/vet-details';

  const VetDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vet Details'),
      ),
      body: const Center(
        child: Text(
          'Details about Vet services.',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
