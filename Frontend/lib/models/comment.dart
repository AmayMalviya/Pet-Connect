import 'package:pet_connect_app/models/profile.dart';

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final Profile user;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.user,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'],
      postId: map['post_id'],
      userId: map['user_id'],
      content: map['content'],
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
