import 'package:flutter/material.dart';

class ScanPetQrScreen extends StatelessWidget {
  static const routeName = '/scan-pet-qr';

  const ScanPetQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Pet QR'),
        leading: const BackButton(), // Added back button
      ),
      body: const Center(
        child: Text('Scan Pet QR Screen'),
      ),
    );
  }
}