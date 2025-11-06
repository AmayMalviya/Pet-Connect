import 'package:flutter/material.dart';
import 'package:pet_connect_app/models/post.dart';
import 'package:pet_connect_app/screens/create_post_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  static const String routeName = '/community';

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late final Stream<List<Post>> _postsStream;

  @override
  void initState() {
    super.initState();
    _postsStream = Supabase.instance.client
        .from('posts_with_profiles')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((maps) => maps.map((map) => Post.fromMap(map)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Post>>(
        stream: _postsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snapshot.data!;
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return _buildPost(post: posts[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPost({required Post post}) {
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
              CircleAvatar(
                backgroundImage: post.user.photoUrl != null
                    ? NetworkImage(post.user.photoUrl!)
                    : const AssetImage("assets/images/profile_avatar.png")
                        as ImageProvider,
                radius: 20,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${post.user.firstName ?? ''} ${post.user.lastName ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '@${post.user.firstName?.toLowerCase() ?? ''}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(post.content, style: const TextStyle(fontSize: 16)),
          if (post.imageUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(post.imageUrl!, fit: BoxFit.cover),
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
