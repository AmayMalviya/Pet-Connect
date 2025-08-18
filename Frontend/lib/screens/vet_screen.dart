import 'package:flutter/material.dart';
import 'package:pet_connect_app/theme/app_theme.dart';

class VetScreen extends StatelessWidget {
  const VetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Veterinary Services'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          VetServiceCard(
            title: 'General Check-up',
            description: 'Routine examination, vaccination, and deworming.',
            price: '₹700',
          ),
          VetServiceCard(
            title: 'Emergency Care',
            description: '24/7 emergency services for critical conditions.',
            price: '₹2000+',
          ),
          VetServiceCard(
            title: 'Surgery',
            description: 'Advanced surgical procedures with post-operative care.',
            price: '₹5000+',
          ),
          VetServiceCard(
            title: 'Dental Care',
            description: 'Professional dental cleaning and oral health assessment.',
            price: '₹1500',
          ),
        ],
      ),
    );
  }
}

class VetServiceCard extends StatelessWidget {
  final String title;
  final String description;
  final String price;

  const VetServiceCard({
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