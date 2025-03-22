import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    Center(child: Text("Home Screen", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
    Center(child: Text("Community Screen", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
    Center(child: Text("Adoption Screen", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFCF9DF),
      appBar: AppBar(
        backgroundColor: Color(0xFFFCF9DF),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.person, color: Colors.black, size: 28), // Profile Icon
          onPressed: () {
            // Navigate to Profile Screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen()),
            );
          },
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black, // Text & Icons in Black
        unselectedItemColor: Colors.grey[600], 
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        showUnselectedLabels: true,
        elevation: 10,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: "Community"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Adoption"),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFCF9DF),
      appBar: AppBar(
        title: Text("Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFFFCF9DF),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Center(child: Text("Profile Screen", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
    );
  }
}
