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
          gradient: LinearGradient(
            colors: [Color(0xFF76EAD7), Color(0xFFFFD166)], // Playful gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  "Review Pet Details",
                  style: TextStyle(fontSize: 26, fontFamily: 'CaniculeDisplay', fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 15),

                Expanded(
                  child: ListView.builder(
                    itemCount: petData.length,
                    itemBuilder: (context, index) {
                      var pet = petData[index];
                      return Card(
                        child: ListTile(
                          title: Text("${pet["name"]} (${pet["type"]})"),
                          subtitle: Text("Breed: ${pet["breed"]}, Age: ${pet["age"]}"),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () => _finishSignup(context),
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
