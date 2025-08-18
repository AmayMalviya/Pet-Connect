import 'package:flutter/material.dart';
import 'package:pet_connect_app/theme/app_theme.dart';

class GroomingScreen extends StatelessWidget {
  const GroomingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grooming Services'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          GroomingServiceCard(
            title: 'Basic Bath & Brush',
            description: 'Includes shampoo, conditioner, and blow-dry.',
            price: '₹500',
          ),
          GroomingServiceCard(
            title: 'Full Groom',
            description: 'Includes bath, brush, haircut, nail trim, and ear cleaning.',
            price: '₹1200',
          ),
          GroomingServiceCard(
            title: 'Nail Trim',
            description: 'Quick and painless nail trimming.',
            price: '₹200',
          ),
          GroomingServiceCard(
            title: 'Dental Cleaning',
            description: 'Non-anesthetic dental cleaning for fresh breath.',
            price: '₹800',
          ),
        ],
      ),
    );
  }
}

class GroomingServiceCard extends StatelessWidget {
  final String title;
  final String description;
  final String price;

  const GroomingServiceCard({
    super.key,
    required this.title,
    required this.description,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(description, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                price,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}