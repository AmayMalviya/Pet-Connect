import 'package:flutter/material.dart';

class AdoptionScreen extends StatelessWidget {
  const AdoptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pet Adoption")),
      body: Center(child: Text("Find your new pet!")),
    );
  }
}
