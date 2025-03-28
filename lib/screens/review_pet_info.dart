import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'main_screen.dart';

class ReviewPetInfoScreen extends StatelessWidget {
  final List<Map<String, dynamic>> petData;

  const ReviewPetInfoScreen({super.key, required this.petData});

  void _finishSignup(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('petData', jsonEncode(petData)); // Store pet data as JSON

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFF4A907F), // Matching HomeScreen Background
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Review Pet Details",
                  style: TextStyle(
                    fontSize: 26,
                    fontFamily: 'CaniculeDisplay',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),

                // Pet Details List
                Expanded(
                  child: ListView.builder(
                    itemCount: petData.length,
                    itemBuilder: (context, index) {
                      var pet = petData[index];
                      return Card(
                        color: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(15),
                          leading: CircleAvatar(
                            backgroundColor: Color(0xFF355C7D),
                            child: Icon(Icons.pets, color: Colors.white),
                          ),
                          title: Text(
                            "${pet["name"]} (${pet["type"]})",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          subtitle: Text(
                            "Breed: ${pet["breed"]}, Age: ${pet["age"]}",
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 20),

                // Finish Button
                ElevatedButton(
                  onPressed: () => _finishSignup(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF355C7D),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  child: Text("Finish Setup 🎉"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
