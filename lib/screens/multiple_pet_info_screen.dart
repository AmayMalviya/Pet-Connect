import 'package:flutter/material.dart';
import 'review_pet_info.dart';

class MultiplePetInfoScreen extends StatefulWidget {
  final int petCount;

  const MultiplePetInfoScreen({super.key, required this.petCount});

  @override
  _MultiplePetInfoScreenState createState() => _MultiplePetInfoScreenState();
}

class _MultiplePetInfoScreenState extends State<MultiplePetInfoScreen> {
  late List<TextEditingController> _nameControllers;
  late List<String?> _selectedPetTypes;
  late List<String?> _selectedPetBreeds;
  late List<int?> _selectedPetAges;

  @override
  void initState() {
    super.initState();
    _nameControllers = List.generate(widget.petCount, (index) => TextEditingController());
    _selectedPetTypes = List.filled(widget.petCount, null);
    _selectedPetBreeds = List.filled(widget.petCount, null);
    _selectedPetAges = List.filled(widget.petCount, null);
  }

  void _savePetDetails() {
    List<Map<String, dynamic>> petData = [];

    for (int i = 0; i < widget.petCount; i++) {
      if (_nameControllers[i].text.isEmpty ||
          _selectedPetTypes[i] == null ||
          _selectedPetBreeds[i] == null ||
          _selectedPetAges[i] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please fill all details for Pet ${i + 1}"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      petData.add({
        "name": _nameControllers[i].text,
        "type": _selectedPetTypes[i],
        "breed": _selectedPetBreeds[i],
        "age": _selectedPetAges[i].toString(), // Convert age to string for JSON storage
      });
    }

    // Navigate to Review Screen with pet data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewPetInfoScreen(petData: petData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF76EAD7), Color(0xFF76EAD7)], // Playful gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Enter details for your pets",
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'CaniculeDisplay',
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.petCount,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 15),
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Pet ${index + 1} Details",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          SizedBox(height: 10),

                          // Pet Name Input
                          TextField(
                            controller: _nameControllers[index],
                            decoration: InputDecoration(
                              labelText: "Pet Name",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                              prefixIcon: Icon(Icons.pets, color: Color(0xFF355C7D)),
                            ),
                          ),
                          SizedBox(height: 10),

                          // Pet Type Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedPetTypes[index],
                            items: ["Dog", "Cat", "Bird", "Rabbit", "Other"]
                                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                                .toList(),
                            onChanged: (value) => setState(() => _selectedPetTypes[index] = value),
                            decoration: InputDecoration(
                              labelText: "Pet Type",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                          SizedBox(height: 10),

                          // Pet Breed Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedPetBreeds[index],
                            items: ["Labrador", "Persian Cat", "Parrot", "Husky", "Mixed Breed"]
                                .map((breed) => DropdownMenuItem(value: breed, child: Text(breed)))
                                .toList(),
                            onChanged: (value) => setState(() => _selectedPetBreeds[index] = value),
                            decoration: InputDecoration(
                              labelText: "Pet Breed",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                          SizedBox(height: 10),

                          // Pet Age Dropdown
                          DropdownButtonFormField<int>(
                            value: _selectedPetAges[index],
                            items: List.generate(20, (i) => i + 1)
                                .map((age) => DropdownMenuItem(value: age, child: Text("$age years")))
                                .toList(),
                            onChanged: (value) => setState(() => _selectedPetAges[index] = value),
                            decoration: InputDecoration(
                              labelText: "Pet Age",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Save Button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: ElevatedButton(
                  onPressed: _savePetDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF355C7D),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  child: Text("Save & Continue"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
