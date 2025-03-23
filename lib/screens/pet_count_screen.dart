import 'package:flutter/material.dart';
import 'pet_basic_info_screen.dart';
import 'multiple_pet_info_screen.dart'; // Create this screen for multiple pets

class PetCountScreen extends StatefulWidget {
  const PetCountScreen({super.key});

  @override
  _PetCountScreenState createState() => _PetCountScreenState();
}

class _PetCountScreenState extends State<PetCountScreen> {
  int? _selectedPetCount;

  void _nextScreen() {
    if (_selectedPetCount != null) {
      if (_selectedPetCount == 1) {
        // If only one pet, navigate to PetBasicInfoScreen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PetBasicInfoScreen(petCount: _selectedPetCount!),
          ),
        );
      } else {
        // If more than one pet, navigate to MultiplePetInfoScreen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MultiplePetInfoScreen(petCount: _selectedPetCount!), // Create this screen
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select the number of pets")),
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
                  "How many pets do you have?",
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'CaniculeDisplay',
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 20),

                // Dropdown Box
                Container(
                  width: 270,
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                  ),
                  child: DropdownButtonFormField<int>(
                    value: _selectedPetCount,
                    items: List.generate(20, (index) => index + 1)
                        .map((count) => DropdownMenuItem(
                              value: count,
                              child: Text("$count", style: TextStyle(fontSize: 16)),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedPetCount = value),
                    decoration: InputDecoration(
                      labelText: "Select number of pets",
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
