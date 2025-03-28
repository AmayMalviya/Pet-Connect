import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Map<String, String>> petData = [];

  @override
  void initState() {
    super.initState();
    _loadPetData();
  }

  Future<void> _loadPetData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? petDataString = prefs.getString('petData');

    if (petDataString != null) {
      List<dynamic> decodedList = jsonDecode(petDataString);
      setState(() {
        petData = List<Map<String, String>>.from(
            decodedList.map((pet) => Map<String, String>.from(pet)));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFCF9DF), // Consistent background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white, size: 28),
          onPressed: () {
            // TODO: Add Sidebar Navigation
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white, size: 28),
            onPressed: () {
              // TODO: Open Settings Screen
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile Header with Gradient
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A907F), Color(0xFF4A907F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                // Profile Picture
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage("assets/images/profile_avatar.png"), // Replace with user's image
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 16,
                        child: Icon(Icons.camera_alt, size: 16, color: Colors.black),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  "Amay Malviya",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Indore, Madhya Pradesh",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Profile Details
          Expanded(
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInfoCard("Name", "Amay Malviya "),
                  _buildInfoCard("Email", "Abc@gmail.com"),
                  _buildInfoCard("Password", "**********", isPassword: true),
                  _buildInfoCard("User ID", "22200"),
                  _buildInfoCard("Zip Code", "08817"),
                  SizedBox(height: 20),

                  // Your Pets Section
                  petData.isNotEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Your Pets",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                            ),
                            SizedBox(height: 10),
                            Expanded(
                              child: ListView.builder(
                                itemCount: petData.length,
                                itemBuilder: (context, index) {
                                  var pet = petData[index];
                                  return Card(
                                    margin: EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    child: Padding(
                                      padding: EdgeInsets.all(15.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${pet["name"]} (${pet["type"]})",
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text("Breed: ${pet["breed"]}"),
                                          Text("Gender: ${pet["gender"]}"),
                                          Text("Age: ${pet["age"]}"),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Text(
                            "No pet details available.",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card Widget for User Details
  Widget _buildInfoCard(String title, String value, {bool isPassword = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 5),
              Text(
                isPassword ? "********" : value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (isPassword)
            Icon(Icons.visibility_off, color: Colors.grey),
        ],
      ),
    );
  }
}
