import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    Center(child: Text("🏡 Home", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
    Center(child: Text("🌍 Community", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
    Center(child: Text("🐾 Adoption", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
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
        centerTitle: true,
        title: Text(
          "Pet Connect",
          style: TextStyle(fontFamily: 'CaniculeDisplay', fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        leading: IconButton(
          icon: Icon(Icons.person, color: Colors.black, size: 28), 
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
          },
        ),
      ),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF355C7D), // Themed Color
        unselectedItemColor: Colors.grey[600], 
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        showUnselectedLabels: true,
        elevation: 10,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.forum_rounded), label: "Community"),
          BottomNavigationBarItem(icon: Icon(Icons.volunteer_activism), label: "Adoption"),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add quick action (maybe add a new pet or open chat)
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Quick action tapped!")));
        },
        backgroundColor: Color(0xFF355C7D),
        child: Icon(Icons.add, size: 28, color: Colors.white),
      ),
    );
  }
}

// Profile Screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
      body: Center(child: Text("👤 Profile Screen", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
    );
  }
}
