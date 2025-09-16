import 'package:flutter/material.dart';

class AppointmentsScreen extends StatelessWidget {
  static const routeName = '/appointments';

  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        leading: const BackButton(), // Added back button
      ),
      body: const Center(
        child: Text('Appointments Screen'),
      ),
    );
  }
}