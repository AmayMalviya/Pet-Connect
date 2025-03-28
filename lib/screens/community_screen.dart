import 'package:flutter/material.dart';
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFCF9DF), // Matching background color from MainScreen
      appBar: AppBar(
        backgroundColor: Color(0xFF4A907F), // Matching MainScreen theme
        title: Text(
          "Community",
          style: TextStyle(
            fontFamily: 'CaniculeDisplay',
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildPost(
            username: "Luna's Owner",
            handle: "@lunalover",
            content: "Luna just learned a new trick! 🐶✨",
            imageUrl: "assets/images/dog_trick.png",
          ),
          _buildPost(
            username: "Milo the Cat",
            handle: "@milomeow",
            content: "Lazy Sundays be like... 🐱💤",
            imageUrl: "assets/images/cat_sleep.png",
          ),
          _buildPost(
            username: "Buddy's Dad",
            handle: "@buddybarks",
            content: "What’s the best food for senior dogs? Any suggestions? 🐕‍🦺",
            imageUrl: null,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF4A907F),
        onPressed: () {
          // Future: Add post-creation logic
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Create Post feature coming soon!")),
          );
        },
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPost({
    required String username,
    required String handle,
    required String content,
    String? imageUrl,
  }) {
    return Container(
      padding: EdgeInsets.all(15),
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage("assets/images/profile_avatar.png"),
                radius: 20,
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(username, style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(handle, style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(content, style: TextStyle(fontSize: 16)),
          if (imageUrl != null) ...[
            SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(imageUrl, fit: BoxFit.cover),
            ),
          ],
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.comment, color: Colors.grey),
              Icon(Icons.favorite_border, color: Colors.grey),
              Icon(Icons.share, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
}
