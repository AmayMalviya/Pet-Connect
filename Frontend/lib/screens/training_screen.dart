import 'package:flutter/material.dart';
import 'package:pet_connect_app/theme/app_theme.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Programs'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          TrainingProgramCard(
            title: 'Puppy Obedience',
            description: 'Basic commands, leash training, and socialization for puppies.',
            duration: '6 weeks',
            price: '₹3000',
          ),
          TrainingProgramCard(
            title: 'Advanced Obedience',
            description: 'Off-leash commands, complex tricks, and behavior modification.',
            duration: '8 weeks',
            price: '₹5000',
          ),
          TrainingProgramCard(
            title: 'Agility Training',
            description: 'Fun and challenging course for active dogs.',
            duration: '10 weeks',
            price: '₹6000',
          ),
        ],
      ),
    );
  }
}

class TrainingProgramCard extends StatelessWidget {
  final String title;
  final String description;
  final String duration;
  final String price;

  const TrainingProgramCard({
    super.key,
    required this.title,
    required this.description,
    required this.duration,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  duration,
                  style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
                Text(
                  price,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}