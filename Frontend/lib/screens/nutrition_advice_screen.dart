import 'package:flutter/material.dart';

class NutritionAdviceScreen extends StatelessWidget {
  static const String routeName = '/nutrition-advice';

  const NutritionAdviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Advice'),
        leading: const BackButton(), // Added back button
      ),
      body: const Center(
        child: Text(
          'Details about Nutrition Advice.',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}