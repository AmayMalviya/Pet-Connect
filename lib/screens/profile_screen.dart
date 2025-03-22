import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
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
        petData = List<Map<String, String>>.from(decodedList.map((pet) => Map<String, String>.from(pet)));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFCF9DF),
      appBar: AppBar(
        title: Text("Profile", style: TextStyle(fontFamily: 'CaniculeDisplay')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: petData.isEmpty
            ? Center(child: Text("No pet details available.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Your Pets", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'CaniculeDisplay')),
                  SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: petData.length,
                      itemBuilder: (context, index) {
                        var pet = petData[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: EdgeInsets.all(15.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${pet["name"]} (${pet["type"]})", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                SizedBox(height: 5),
                                Text("Breed: ${pet["breed"]}", style: TextStyle(fontSize: 16)),
                                Text("Gender: ${pet["gender"]}", style: TextStyle(fontSize: 16)),
                                Text("Age: ${pet["age"]}", style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
