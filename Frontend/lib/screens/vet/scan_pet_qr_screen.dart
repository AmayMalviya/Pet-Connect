import 'package:flutter/material.dart';

class ScanPetQrScreen extends StatelessWidget {
  static const routeName = '/vet-scan-pet-qr';

  const ScanPetQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Pet QR'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.qr_code_scanner,
                size: 120, // Increased size
                color: Theme.of(context).primaryColor, // Added color
              ),
              const SizedBox(height: 30), // Increased spacing
              Text(
                'Feature Coming Soon!', // More engaging title
                style: Theme.of(context).textTheme.headlineMedium?.copyWith( // Changed headline4 to headlineMedium
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15), // Increased spacing
              Text(
                'We are working hard to bring you this exciting feature. Stay tuned for updates!', // More descriptive message
                style: Theme.of(context).textTheme.bodyMedium, // Changed bodyText1 to bodyMedium
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}