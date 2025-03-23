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
        SnackBar(content: Text("Please select breed and age")),
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
                  "Select Pet Details",
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'CaniculeDisplay',
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 20),

                // Breed Dropdown
                Container(
                  width: 270,
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
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
                      labelStyle: TextStyle(color: Colors.black54),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                SizedBox(height: 15),

                // Age Dropdown
                Container(
                  width: 270,
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
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
