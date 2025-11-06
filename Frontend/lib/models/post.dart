import 'package:pet_connect_app/models/profile.dart';

class Post {
  final String id;
  final String userId;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final Profile user;

  Post({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    required this.user,
  });

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'],
      userId: map['user_id'],
      content: map['content'],
      imageUrl: map['image_url'],
      createdAt: DateTime.parse(map['created_at']),
      user: Profile(
        userId: map['user_id'],
        firstName: map['first_name'],
        lastName: map['last_name'],
        photoUrl: map['photo_url'],
      ),
    );
  }
}
