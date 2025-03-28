import 'package:flutter/material.dart';
import 'review_pet_info.dart';

class PetBreedAgeScreen extends StatefulWidget {
  final String petName;
  final String petType;
  final int petCount;

  const PetBreedAgeScreen({super.key, required this.petName, required this.petType, required this.petCount});

  @override
  _PetBreedAgeScreenState createState() => _PetBreedAgeScreenState();
}

class _PetBreedAgeScreenState extends State<PetBreedAgeScreen> {
  String? _selectedBreed;
  String? _selectedAge;

  final Map<String, List<String>> breedMap = {
    "Dog": ["Labrador", "Bulldog", "Beagle", "Poodle", "Other"],
    "Cat": ["Persian", "Siamese", "Bengal", "Maine Coon", "Other"],
    "Rabbit": ["Holland Lop", "Netherland Dwarf", "Flemish Giant", "Other"],
    "Bird": ["Parrot", "Canary", "Finch", "Other"],
  };

  final List<String> ages = ["Less than 1 year", "1-3 years", "4-6 years", "7+ years"];

  void _nextScreen() {
    if (_selectedBreed != null && _selectedAge != null) {
      List<Map<String, String>> petData = [
        {
          "name": widget.petName,
          "type": widget.petType,
          "breed": _selectedBreed!,
          "age": _selectedAge!,
        }
      ];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewPetInfoScreen(petData: petData),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select breed and age"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF4A907F), // Matches Main Screen
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Select Pet Details",
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'CaniculeDisplay',
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 25),

                // Breed Dropdown
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedBreed,
                    items: (breedMap[widget.petType] ?? [])
                        .map((breed) => DropdownMenuItem(
                              value: breed,
                              child: Text(breed, style: TextStyle(fontSize: 16)),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedBreed = value),
                    decoration: InputDecoration(
                      labelText: "Breed",
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.pets, color: Color(0xFF355C7D)),
                    ),
                  ),
                ),

                SizedBox(height: 15),

                // Age Dropdown
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedAge,
                    items: ages
                        .map((age) => DropdownMenuItem(
                              value: age,
                              child: Text(age, style: TextStyle(fontSize: 16)),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedAge = value),
                    decoration: InputDecoration(
                      labelText: "Age",
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.cake, color: Color(0xFF355C7D)),
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
    );
  }
}
