import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pet_count_screen.dart'; // Redirect to PetCountScreen

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _signup() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fill all fields"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', name);
    await prefs.setString('email', email);
    await prefs.setString('password', password);
    await prefs.setBool('isLoggedIn', false); // User must complete pet info first

    // Navigate to Pet Count Screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => PetCountScreen()), 
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 28,
                    fontFamily: 'CaniculeDisplay',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),

                // Input Fields Box
                Container(
                  width: 270, // Same width as LoginScreen
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        style: TextStyle(fontSize: 16, color: Colors.black87), // Fixes text visibility
                        decoration: InputDecoration(
                          labelText: "Full Name",
                          labelStyle: TextStyle(color: Colors.black54),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                          prefixIcon: Icon(Icons.person, color: Color(0xFF355C7D)),
                        ),
                      ),
                      SizedBox(height: 15),
                      TextField(
                        controller: _emailController,
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: "Email",
                          labelStyle: TextStyle(color: Colors.black54),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                          prefixIcon: Icon(Icons.email, color: Color(0xFF355C7D)),
                        ),
                      ),
                      SizedBox(height: 15),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: "Password",
                          labelStyle: TextStyle(color: Colors.black54),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                          prefixIcon: Icon(Icons.lock, color: Color(0xFF355C7D)),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Next Button
                ElevatedButton(
                  onPressed: _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF355C7D),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 80),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  child: Text("Next ➡️"),
                ),

                SizedBox(height: 30),

                // Login Redirect
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Go back to LoginScreen
                  },
                  child: Text(
                    "Already have an account? Login",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
