import 'package:pet_connect_app/models/profile.dart';

class Post {
  final String id;
  final String userId;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final Profile user;
  final int likeCount;
  final int commentCount;

  Post({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    required this.user,
    required this.likeCount,
    required this.commentCount,
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
      likeCount: map['like_count'] ?? 0,
      commentCount: map['comment_count'] ?? 0,
    );
  }
}
