import 'package:flutter/material.dart';
import 'pet_breed_age_screen.dart';

class PetBasicInfoScreen extends StatefulWidget {
  final int petCount;

  PetBasicInfoScreen({required this.petCount});

  @override
  _PetBasicInfoScreenState createState() => _PetBasicInfoScreenState();
}

class _PetBasicInfoScreenState extends State<PetBasicInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _selectedType;

  final List<String> animalTypes = ["Dog", "Cat", "Rabbit", "Bird", "Other"];

  void _nextScreen() {
    if (_nameController.text.isNotEmpty && _selectedType != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PetBreedAgeScreen(
            petName: _nameController.text,
            petType: _selectedType!,
            petCount: widget.petCount,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter name and select pet type")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFCF9DF),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Enter Pet Details", style: TextStyle(fontSize: 22, fontFamily: 'CaniculeDisplay')),
              SizedBox(height: 15),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "Pet Name"),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField(
                value: _selectedType,
                items: animalTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (value) => setState(() => _selectedType = value as String?),
                decoration: InputDecoration(labelText: "Animal Type"),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _nextScreen,
                child: Text("Next"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
