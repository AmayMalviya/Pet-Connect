import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_screen.dart';

class ReviewPetInfoScreen extends StatelessWidget {
  final List<Map<String, String>> petData;

  ReviewPetInfoScreen({required this.petData});

  void _finishSignup(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('petData', petData.toString());

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFCF9DF),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Review Pet Details", style: TextStyle(fontSize: 24, fontFamily: 'CaniculeDisplay')),
            SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: petData.map((pet) {
                  return Card(
                    child: ListTile(
                      title: Text("${pet["name"]} (${pet["type"]})"),
                      subtitle: Text("Breed: ${pet["breed"]}, Age: ${pet["age"]}"),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _finishSignup(context),
              child: Text("Finish SetUp"),
            ),
          ],
        ),
      ),
    );
  }
}
