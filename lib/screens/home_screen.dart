import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pet Care Home")),
      body: Center(child: Text("Welcome to Pet Care App!", style: TextStyle(fontSize: 18))),
    );
  }
}
