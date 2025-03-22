import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pet_connect/screens/launch_screen.dart';
import 'package:pet_connect/screens/login_screen.dart';
import 'package:pet_connect/screens/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(PetConnectApp());
}

class PetConnectApp extends StatelessWidget {
  const PetConnectApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pet Connect',
      theme: ThemeData(
        fontFamily: 'CaniculeDisplay', // Custom font
        scaffoldBackgroundColor: Color(0xFFFCF9DF), // Background color
      ),
      home: SplashScreen(), // First screen on launch
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(Duration(seconds: 3)); // Show LaunchScreen for 3 sec
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => isLoggedIn ? MainScreen() : LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LaunchScreen(); // Display LaunchScreen first
  }
}
