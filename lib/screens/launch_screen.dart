import 'package:flutter/material.dart';
import 'package:pet_connect/screens/main_screen.dart';  // Ensure this import is correct

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  _LaunchScreenState createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()), // Redirect to MainScreen
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFCF9DF), // Background color
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: double.infinity,  // Makes image take full width
          height: double.infinity, // Makes image take full height
          fit: BoxFit.cover, // Ensures the image fills the screen
        ),
      ),
    );
  }
}
