import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: Colors.grey[50],
      body: StreamBuilder<List<Post>>(
        stream: _postsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: GoogleFonts.poppins(),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snapshot.data!;
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.dynamic_feed_rounded,
                      size: 36,
                      color: Colors.grey[300],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No posts yet',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Be the first to share!',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            itemCount: posts.length,
            itemBuilder: (context, index) => _PostCard(
              post: posts[index],
              onDelete: _deletePostWithDependencies,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreatePostScreen()),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _deletePostWithDependencies(String postId) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase.from('comments').delete().eq('post_id', postId);
      await supabase.from('likes').delete().eq('post_id', postId);
      try {
        final mediaRes =
            await supabase.from('media').select().eq('post_id', postId)
                as List<dynamic>?;
        if (mediaRes != null) {
          for (final m in mediaRes) {
            try {
              final map = Map<String, dynamic>.from(m as Map);
              final url = map['url'] as String? ?? map['file_path'] as String?;
              await _deleteStorageFile(url);
            } catch (err) {
              debugPrint('Error deleting media file: $err');
            }
          }
        }
        await supabase.from('media').delete().eq('post_id', postId);
      } catch (_) {
        // Media table missing, ignore
      }
      await supabase.from('posts').delete().eq('id', postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Post deleted',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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
        }
      } catch (_) {
        final parts = urlOrPath.split('/');
        if (parts.length > 1) {
          bucket = parts.first;
          path = parts.sublist(1).join('/');
        }
      }
      if (path.isEmpty) return;
      await Supabase.instance.client.storage.from(bucket).remove([path]);
    } catch (e) {
      debugPrint('Storage remove error: $e');
    }
  }
}

// ── Post Card ─────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final Post post;
  final Future<void> Function(String) onDelete;

  const _PostCard({required this.post, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwner = currentUserId != null && currentUserId == post.userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 0),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[200]!, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: post.user.photoUrl != null
                        ? NetworkImage(post.user.photoUrl!)
                        : const AssetImage('assets/images/profile_avatar.png')
                              as ImageProvider,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${post.user.firstName ?? ''} ${post.user.lastName ?? ''}'
                            .trim(),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '@${post.user.firstName?.toLowerCase() ?? 'user'}',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (v) async {
                      if (v == 'delete') {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (dctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: Text(
                              'Delete post?',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            content: Text(
                              'This will permanently remove your post.',
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dctx, false),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(dctx, true),
                                child: Text(
                                  'Delete',
                                  style: GoogleFonts.poppins(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) await onDelete(post.id);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Delete Post',
                              style: GoogleFonts.poppins(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Text(
              post.content,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),

          // Image
          if (post.imageUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Image.network(
                post.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 14, 10),
            child: Row(
              children: [
                // Comment
                _ActionTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: post.commentCount.toString(),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommentsScreen(postId: post.id),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                LikeButton(post: post),
                const Spacer(),
                Icon(
                  Icons.ios_share_rounded,
                  size: 18,
                  color: Colors.grey[350],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Like Button ───────────────────────────────────────────────────────────────

class LikeButton extends StatefulWidget {
  final Post post;
  const LikeButton({super.key, required this.post});

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton>
    with SingleTickerProviderStateMixin {
  bool _isLiked = false;
  bool _isLoading = true;
  final _supabase = Supabase.instance.client;

  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _bounceAnim = Tween<double>(
      begin: 1,
      end: 1.4,
    ).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOut));
    _fetchLikeStatus();
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLikeStatus() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
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
    setState(() => _isLoading = true);
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to like a post.')),
      );
      setState(() => _isLoading = false);
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
      _bounceCtrl.forward().then((_) => _bounceCtrl.reverse());
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
        width: 36,
        height: 36,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return InkWell(
      onTap: _toggleLike,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            ScaleTransition(
              scale: _bounceAnim,
              child: Icon(
                _isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 18,
                color: _isLiked ? Colors.red : Colors.grey,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              widget.post.likeCount.toString(),
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
