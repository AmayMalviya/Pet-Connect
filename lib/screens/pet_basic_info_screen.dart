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
        SnackBar(content: Text("Please enter pet name and select pet type")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF76EAD7), Color(0xFFFFD166)], // Playful gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
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
                ),
                SizedBox(height: 20),

                // Pet Name Input Box
                Container(
                  width: 270,
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                  ),
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Pet Name",
                      labelStyle: TextStyle(color: Colors.black54),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                SizedBox(height: 15),

                // Animal Type Dropdown
                Container(
                  width: 270,
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
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
                      labelStyle: TextStyle(color: Colors.black54),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                SizedBox(height: 20),

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
    );
  }
}
