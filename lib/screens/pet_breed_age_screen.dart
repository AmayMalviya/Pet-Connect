import 'package:flutter/material.dart';
import 'review_pet_info.dart';

class PetBreedAgeScreen extends StatefulWidget {
  final String petName;
  final String petType;
  final int petCount;

  PetBreedAgeScreen({required this.petName, required this.petType, required this.petCount});

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
      backgroundColor: Color(0xFFFCF9DF),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Select Pet Details", style: TextStyle(fontSize: 22, fontFamily: 'CaniculeDisplay')),
              SizedBox(height: 15),
              DropdownButtonFormField(
                value: _selectedBreed,
                items: (breedMap[widget.petType] ?? [])
                    .map((breed) => DropdownMenuItem(value: breed, child: Text(breed)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedBreed = value as String?),
                decoration: InputDecoration(labelText: "Breed"),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField(
                value: _selectedAge,
                items: ages.map((age) => DropdownMenuItem(value: age, child: Text(age))).toList(),
                onChanged: (value) => setState(() => _selectedAge = value as String?),
                decoration: InputDecoration(labelText: "Age"),
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
