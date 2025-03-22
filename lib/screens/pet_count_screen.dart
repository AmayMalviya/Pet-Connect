import 'package:flutter/material.dart';
import 'pet_basic_info_screen.dart';

class PetCountScreen extends StatefulWidget {
  @override
  _PetCountScreenState createState() => _PetCountScreenState();
}

class _PetCountScreenState extends State<PetCountScreen> {
  int? _selectedPetCount;

  void _nextScreen() {
    if (_selectedPetCount != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PetBasicInfoScreen(petCount: _selectedPetCount!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select the number of pets")),
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
              Text(
                "How many pets do you have?",
                style: TextStyle(fontSize: 22, fontFamily: 'CaniculeDisplay'),
              ),
              SizedBox(height: 15),
              DropdownButtonFormField<int>(
                value: _selectedPetCount,
                items: List.generate(20, (index) => index + 1)
                    .map((count) => DropdownMenuItem(
                          value: count,
                          child: Text("$count"),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedPetCount = value),
                decoration: InputDecoration(labelText: "Select number of pets"),
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
