import 'package:flutter/material.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  static const String routeName = '/community';

  @override
  Widget build(BuildContext context) {
    return ListView(
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
    );
  }

  Widget _buildPost({
    required String username,
    required String handle,
    required String content,
    String? imageUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundImage: AssetImage("assets/images/profile_avatar.png"),
                radius: 20,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(handle, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(content, style: const TextStyle(fontSize: 16)),
          if (imageUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(imageUrl, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 10),
          const Row(
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
