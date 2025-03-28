import 'package:flutter/material.dart';
import 'pet_breed_age_screen.dart';

class PetBasicInfoScreen extends StatefulWidget {
  final int petCount;

  const PetBasicInfoScreen({super.key, required this.petCount});

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
        SnackBar(
          content: Text("Please enter pet name and select pet type"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A907F), Color(0xFF4A907F)], // Playful gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Enter Pet Details",
                    style: TextStyle(
                      fontSize: 24,
                      fontFamily: 'CaniculeDisplay',
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 25),

                  // Pet Name Input Box
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                    ),
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: "Pet Name",
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.pets, color: Color(0xFF355C7D)),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Animal Type Dropdown
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedType,
                      items: animalTypes
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type, style: TextStyle(fontSize: 16)),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedType = value),
                      decoration: InputDecoration(
                        labelText: "Animal Type",
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.category, color: Color(0xFF355C7D)),
                      ),
                    ),
                  ),

                  SizedBox(height: 30),

                  // Next Button
                  ElevatedButton(
                    onPressed: _nextScreen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF355C7D),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 80),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    child: Text("Next ➡️"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
