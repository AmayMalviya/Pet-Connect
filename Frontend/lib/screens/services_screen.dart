import 'package:flutter/material.dart';
import 'package:pet_connect_app/screens/adoption_screen.dart';
import 'package:pet_connect_app/screens/map_screen.dart';
import 'package:pet_connect_app/screens/health_details_screen.dart';
import 'package:pet_connect_app/screens/self_care_options_screen.dart';
// Import AppTheme for colors

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  static const String routeName = '/services';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Services'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30), // Reposition Self Care Card lower
            // Consolidated Pet Care Message and Self Care Button
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Take Care of your pet, good pet care = more ha-paw-nessss...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor, // Use primary color
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, SelfCareOptionsScreen.routeName);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor, // Use primary color
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10), // Reduced button size
                      ),
                      child: const Text(
                        'Self Care',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20), // Reposition cards lower
            // Other Services
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                ServiceCard(
                  title: 'Health Track',
                  icon: Icons.medical_services_outlined,
                  onTap: () => Navigator.pushNamed(context, HealthDetailsScreen.routeName),
                  cardHeight: 120, // Smaller height
                  iconSize: 30, // Smaller icon
                  textSize: 14, // Smaller text
                ),
                ServiceCard(
                  title: 'Adoption',
                  icon: Icons.pets,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdoptionScreen())),
                  cardHeight: 120, // Smaller height
                  iconSize: 30, // Smaller icon
                  textSize: 14, // Smaller text
                ),
              ],
            ),
            const SizedBox(height: 16), // Spacing before Vets near me card
            // Vets near me card (repositioned and resized)
            ServiceCard(
              title: 'Vets near me',
              icon: Icons.map,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen())),
              cardHeight: 80, // Decreased height
              iconSize: 30, // Adjusted icon size
              textSize: 16, // Adjusted text size
              isWide: true, // Increase horizontally
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final double cardHeight;
  final double iconSize;
  final double textSize;
  final bool isWide;

  const ServiceCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.cardHeight = 150, // Default height
    this.iconSize = 50, // Default icon size
    this.textSize = 18, // Default text size
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2, // Added elevation for better visual
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: cardHeight,
          width: isWide ? double.infinity : null, // Make wide if isWide is true
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: iconSize),
              const SizedBox(height: 8),
              Text(title, style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
