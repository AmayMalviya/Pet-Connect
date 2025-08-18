import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pet_connect_app/theme/app_theme.dart';
import 'package:pet_connect_app/widgets/app_drawer.dart';
import 'package:pet_connect_app/screens/profile_screen.dart';
import 'package:pet_connect_app/screens/grooming_screen.dart';
import 'package:pet_connect_app/screens/training_screen.dart';
import 'package:pet_connect_app/screens/vet_screen.dart';
import 'package:pet_connect_app/screens/adoption_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _vetNames = [
    'Dr. Aarav Sharma',
    'Dr. Vivaan Gupta',
    'Dr. Aditya Singh',
    'Dr. Ishaan Patel',
    'Dr. Reyansh Kumar',
  ];

  @override
  Widget build(BuildContext context) {
    return _buildHomeScreen();
  }

  Widget _buildHomeScreen() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Good Morning, Amay!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search for services, products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Pet care'),
            const SizedBox(height: 10),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  PetCareCard(
                    title: 'Grooming',
                    icon: Icons.cut,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => GroomingScreen()));
                    },
                  ),
                  PetCareCard(
                    title: 'Training',
                    icon: Icons.school,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => TrainingScreen()));
                    },
                  ),
                  PetCareCard(
                    title: 'Vet',
                    icon: Icons.medical_services,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => VetScreen()));
                    },
                  ),
                  PetCareCard(
                    title: 'Adoption',
                    icon: Icons.favorite_border,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => AdoptionScreen()));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Nearby Vets'),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                final random = Random();
                final vetName = _vetNames[random.nextInt(_vetNames.length)];
                return VetCard(
                  name: vetName,
                  address: '123 Main Street, Anytown, USA',
                  rating: 4.5,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

class PetCareCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const PetCareCard({super.key, required this.title, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(right: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Theme.of(context).primaryColor),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class VetCard extends StatelessWidget {
  final String name;
  final String address;
  final double rating;

  const VetCard({
    super.key,
    required this.name,
    required this.address,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage(
                'assets/images/logo.png',
              ), // Add vet image
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(address, style: TextStyle(color: AppColors.textDark)),
                ],
              ),
            ),
            Row(
              children: [
                const Icon(Icons.star, color: AppColors.primary),
                Text(
                  rating.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
