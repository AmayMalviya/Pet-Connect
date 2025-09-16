import 'package:flutter/material.dart';

class VetProfileScreen extends StatelessWidget {
  static const routeName = '/vet-profile';

  const VetProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vet Profile'),
      ),
      body: const Center(
        child: Text('Vet Profile Screen'),
      ),
    );
  }
}
