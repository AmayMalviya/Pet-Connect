import 'package:flutter/material.dart';
import 'package:pet_connect_app/screens/adoption_screen.dart';
import 'package:pet_connect_app/screens/grooming_screen.dart';
import 'package:pet_connect_app/screens/map_screen.dart';
import 'package:pet_connect_app/screens/training_screen.dart';
import 'package:pet_connect_app/screens/vet_screen.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  static const String routeName = '/services';

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        ServiceCard(
          title: 'Grooming',
          icon: Icons.cut,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroomingScreen())),
        ),
        ServiceCard(
          title: 'Training',
          icon: Icons.school,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrainingScreen())),
        ),
        ServiceCard(
          title: 'Vet',
          icon: Icons.medical_services,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VetScreen())),
        ),
        ServiceCard(
          title: 'Adoption',
          icon: Icons.pets,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdoptionScreen())),
        ),
        ServiceCard(
          title: 'Vets near me',
          icon: Icons.map,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen())),
        ),
      ],
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const ServiceCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
