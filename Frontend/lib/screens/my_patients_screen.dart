import 'package:flutter/material.dart';

class MyPatientsScreen extends StatelessWidget {
  static const routeName = '/my-patients';

  const MyPatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Patients'),
        leading: const BackButton(), // Added back button
      ),
      body: const Center(
        child: Text('My Patients Screen'),
      ),
    );
  }
}