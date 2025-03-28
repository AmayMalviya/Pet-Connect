import 'package:flutter/material.dart';
import 'package:pet_connect/screens/community_screen.dart';
import 'package:pet_connect/screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomePage(),
    CommunityScreen(),  // ✅ Fixed: Replaced placeholder with actual screen
    Center(child: Text("🐾 Adoption", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
    ProfileScreen(), // ✅ Fixed: Replaced placeholder with actual screen
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF4A907F),
      appBar: AppBar(
        backgroundColor: Color(0xFF4A907F),
        elevation: 0,
        centerTitle: true,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search...",
              hintStyle: TextStyle(color: Colors.white70),
              border: InputBorder.none,
              icon: Icon(Icons.search, color: Colors.white),
            ),
            style: TextStyle(color: Colors.white),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white, size: 28),
          onPressed: () {
            // TODO: Add Sidebar Navigation
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white, size: 28),
            onPressed: () {
              // TODO: Add Notification Screen
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex], // ✅ Fixed navigation to actual screens
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF355C7D),
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        showUnselectedLabels: true,
        elevation: 10,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.forum_rounded), label: "Community"),
          BottomNavigationBarItem(icon: Icon(Icons.volunteer_activism), label: "Adoption"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

// ✅ Home Page
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CategoryCard(title: "Pet Care", imagePath: "assets/images/pet_care.png"),
              CategoryCard(title: "Products", imagePath: "assets/images/products.png"),
            ],
          ),
          SizedBox(height: 20),

          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Vets Nearby", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    VetNearbyCard(title: "Food Nearby", icon: Icons.fastfood),
                    VetNearbyCard(title: "Products", icon: Icons.shopping_cart),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ServiceCard(title: "Pet Grooming", imagePath: "assets/images/grooming.png"),
              ServiceCard(title: "Meds for Pet", imagePath: "assets/images/meds.png"),
            ],
          ),
        ],
      ),
    );
  }
}

// ✅ Custom Widgets
class CategoryCard extends StatelessWidget {
  final String title;
  final String imagePath;

  const CategoryCard({super.key, required this.title, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, width: 60),
          SizedBox(height: 5),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class VetNearbyCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const VetNearbyCard({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: Color(0xFF355C7D)),
          SizedBox(height: 5),
          Text(title, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String title;
  final String imagePath;

  const ServiceCard({super.key, required this.title, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, width: 60),
          SizedBox(height: 5),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
