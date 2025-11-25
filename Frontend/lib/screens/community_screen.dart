import 'package:flutter/material.dart';
import 'package:pet_connect_app/models/post.dart';
import 'package:pet_connect_app/screens/create_post_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/screens/comments_screen.dart';

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
              Expanded(
                child: Column(
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
              ),
              // If current user is the owner, show delete menu
              Builder(builder: (context) {
                final currentUserId = Supabase.instance.client.auth.currentUser?.id;
                if (currentUserId != null && currentUserId == post.userId) {
                  return PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'delete') {
                        final ok = await showDialog<bool>(context: context, builder: (dctx) => AlertDialog(
                          title: const Text('Delete post?'),
                          content: const Text('This will permanently remove your post and related captions.'),
                          actions: [TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(dctx, true), child: const Text('Delete'))],
                        ));
                        if (ok == true) {
                          await _deletePostWithDependencies(post.id);
                        }
                      }
                    },
                    itemBuilder: (ctx) => const [PopupMenuItem(value: 'delete', child: Text('Delete Post'))],
                  );
                }
                return const SizedBox.shrink();
              }),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.comment, color: Colors.grey),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CommentsScreen(postId: post.id),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 5),
                  Text(post.commentCount.toString()),
                ],
              ),
              LikeButton(post: post),
              const Icon(Icons.share, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deletePostWithDependencies(String postId) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase.from('comments').delete().eq('post_id', postId);
      await supabase.from('likes').delete().eq('post_id', postId);

      // Fetch media rows for the post to delete storage files
      final mediaRes = await supabase.from('media').select().eq('post_id', postId) as List<dynamic>?;
      if (mediaRes != null) {
        for (final m in mediaRes) {
          try {
            final map = Map<String, dynamic>.from(m as Map);
            final url = map['url'] as String? ?? map['file_path'] as String?;
            await _deleteStorageFile(url);
          } catch (err) {
            debugPrint('Error deleting media file for post: $err');
          }
        }
      }

      await supabase.from('media').delete().eq('post_id', postId);
      await supabase.from('posts').delete().eq('id', postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post and related data deleted')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting post: $e')));
    }
  }

  Future<void> _deleteStorageFile(String? urlOrPath) async {
    if (urlOrPath == null || urlOrPath.isEmpty) return;
    try {
      String bucket = 'posts';
      String path = urlOrPath;
      try {
        final uri = Uri.parse(urlOrPath);
        final segments = uri.pathSegments;
        final idx = segments.indexOf('public');
        if (idx != -1 && idx + 1 < segments.length) {
          bucket = segments[idx + 1];
          path = segments.sublist(idx + 2).join('/');
        } else {
          if (segments.isNotEmpty) {
            if (segments.first == bucket) {
              path = segments.sublist(1).join('/');
            } else {
              path = segments.join('/');
            }
          }
        }
      } catch (_) {
        final parts = urlOrPath.split('/');
        if (parts.length > 1) {
          bucket = parts.first;
          path = parts.sublist(1).join('/');
        }
      }
      if (path.isEmpty) return;
      final storage = Supabase.instance.client.storage;
      try {
        await storage.from(bucket).remove([path]);
      } catch (storageErr) {
        debugPrint('Storage remove error: $storageErr');
      }
    } catch (e) {
      debugPrint('Error deleting storage file: $e');
    }
  }
}

class LikeButton extends StatefulWidget {
  final Post post;
  const LikeButton({super.key, required this.post});

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  bool _isLiked = false;
  bool _isLoading = true;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchLikeStatus();
  }

  Future<void> _fetchLikeStatus() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final response = await _supabase
        .from('likes')
        .select()
        .eq('post_id', widget.post.id)
        .eq('user_id', userId)
        .maybeSingle();
    if (mounted) {
      setState(() {
        _isLiked = response != null;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to like a post.')),
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    if (_isLiked) {
      await _supabase
          .from('likes')
          .delete()
          .eq('post_id', widget.post.id)
          .eq('user_id', userId);
    } else {
      await _supabase.from('likes').insert({
        'post_id': widget.post.id,
        'user_id': userId,
      });
    }
    if (mounted) {
      setState(() {
        _isLiked = !_isLiked;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Row(
      children: [
        IconButton(
          icon: Icon(
            _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked ? Colors.red : Colors.grey,
          ),
          onPressed: _toggleLike,
        ),
        Text(widget.post.likeCount.toString()),
      ],
    );
  }
}
