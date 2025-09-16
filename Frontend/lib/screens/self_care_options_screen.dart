import 'package:flutter/material.dart';
import 'package:pet_connect_app/screens/grooming_details_screen.dart';
import 'package:pet_connect_app/screens/training_details_screen.dart';
import 'package:pet_connect_app/screens/vet_details_screen.dart';
import 'package:pet_connect_app/screens/nutrition_advice_screen.dart';

class SelfCareOptionsScreen extends StatefulWidget {
  static const String routeName = '/self-care-options';

  const SelfCareOptionsScreen({super.key});

  @override
  State<SelfCareOptionsScreen> createState() => _SelfCareOptionsScreenState();
}

class _SelfCareOptionsScreenState extends State<SelfCareOptionsScreen> {
  String? _selectedPet;
  final List<String> _petNames = ['Buddy', 'Whiskers', 'Max', 'Bella']; // Placeholder pet names

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Self Care Options'),
        leading: const BackButton(), // Added back button
      ),
      body: Row(
        children: [
          // Left side: Pet selection
          Container(
            width: 120,
            color: Colors.grey[200],
            child: ListView.builder(
              itemCount: _petNames.length,
              itemBuilder: (context, index) {
                final petName = _petNames[index];
                return ListTile(
                  title: Text(petName),
                  selected: _selectedPet == petName,
                  onTap: () {
                    setState(() {
                      _selectedPet = petName;
                    });
                  },
                );
              },
            ),
          ),
          // Right side: Animated options
          Expanded(
            child: Center(
              child: _selectedPet == null
                  ? const Text('Select a pet to see self-care options')
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: _buildSelfCareOptions(_selectedPet!),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfCareOptions(String petName) {
    // Key is important for AnimatedSwitcher to recognize different children
    return Column(
      key: ValueKey<String>(petName), 
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Options for $petName',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        _buildOptionButton('Self Grooming', Icons.cut, GroomingDetailsScreen.routeName),
        _buildOptionButton('Training', Icons.school, TrainingDetailsScreen.routeName),
        _buildOptionButton('Pet Health Care', Icons.health_and_safety, VetDetailsScreen.routeName),
        _buildOptionButton('Nutrition Advice', Icons.food_bank, NutritionAdviceScreen.routeName),
      ],
    );
  }

  Widget _buildOptionButton(String title, IconData icon, String routeName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, routeName);
        },
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(200, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}