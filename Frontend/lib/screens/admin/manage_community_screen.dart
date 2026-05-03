import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/theme/app_theme.dart';
import 'package:pet_connect_app/models/post.dart';
import 'package:pet_connect_app/screens/comments_screen.dart';
import 'package:pet_connect_app/screens/community_screen.dart';

class ManageCommunityScreen extends StatefulWidget {
  static const routeName = '/admin-manage-community';
  const ManageCommunityScreen({super.key});

  @override
  State<ManageCommunityScreen> createState() => _ManageCommunityScreenState();
}

class _ManageCommunityScreenState extends State<ManageCommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _postsFuture;
  late final Stream<List<Post>> _postsStream;
  late Future<List<Map<String, dynamic>>> _mediaFuture;
  late Future<List<Map<String, dynamic>>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _postsFuture = _fetchPosts();
    _postsStream = Supabase.instance.client
      .from('posts_with_profiles')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((maps) => maps.map((m) => Post.fromMap(Map<String, dynamic>.from(m as Map))).toList());
    _mediaFuture = _fetchMedia();
    _usersFuture = _fetchUsers();
  }

  Future<List<Map<String, dynamic>>> _fetchPosts() async {
    try {
      final res = await Supabase.instance.client.from('posts').select('*').order('created_at', ascending: false);
      final list = (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      return list;
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMedia() async {
    try {
      final res = await Supabase.instance.client.from('media').select('*').order('created_at', ascending: false);
      final list = (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      return list;
    } catch (e) {
      // If the 'media' table doesn't exist in the DB, return empty list silently.
      // debugPrint('Error fetching media (returning empty): $e'); // Disabled to stop spamming console
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    try {
      final res = await Supabase.instance.client.from('profiles').select('*').order('created_at', ascending: false);
      final list = (res as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      return list;
    } catch (e) {
      debugPrint('Error fetching users: $e');
      return [];
    }
  }

  Future<void> _deletePost(String postId) async {
    try {
      // Delete dependent rows first: comments (captions), likes
      await Supabase.instance.client.from('comments').delete().eq('post_id', postId);
      await Supabase.instance.client.from('likes').delete().eq('post_id', postId);

      try {
        // Fetch media rows for this post so we can remove files from storage
        final mediaRes = await Supabase.instance.client.from('media').select().eq('post_id', postId) as List<dynamic>?;
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
        // Delete media rows
        await Supabase.instance.client.from('media').delete().eq('post_id', postId);
      } catch (_) {
        // If 'media' table is missing, skip
      }

      // Finally delete the post itself
      await Supabase.instance.client.from('posts').delete().eq('id', postId);

      if (mounted) {
        setState(() {
          _postsFuture = _fetchPosts();
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post and related data deleted')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting post and dependencies: $e')));
    }
  }

  Future<void> _removePostImage(String postId) async {
    try {
      // Fetch current post to get image URL/path
      final res = await Supabase.instance.client.from('posts').select().eq('id', postId).maybeSingle();
      if (res != null && res is Map) {
        final map = Map<String, dynamic>.from(res);
        final url = map['image_url'] as String?;
        await _deleteStorageFile(url);
      }

      await Supabase.instance.client.from('posts').update({'image_url': null}).eq('id', postId);
      if (mounted) {
        setState(() {
          _postsFuture = _fetchPosts();
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post image removed')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error removing image: $e')));
    }
  }

  Future<void> _deleteMedia(String mediaId) async {
    try {
      // Fetch media row to get storage path/url
      final res = await Supabase.instance.client.from('media').select().eq('id', mediaId).maybeSingle();
      if (res != null && res is Map) {
        final map = Map<String, dynamic>.from(res);
        final url = map['url'] as String? ?? map['file_path'] as String?;
        await _deleteStorageFile(url);
      }

      await Supabase.instance.client.from('media').delete().eq('id', mediaId);
      if (mounted) {
        setState(() {
          _mediaFuture = _fetchMedia();
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Media entry deleted')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting media: $e')));
    }
  }

  Future<void> _deleteStorageFile(String? urlOrPath) async {
    if (urlOrPath == null || urlOrPath.isEmpty) return;
    try {
      // Default bucket for posts media
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
      // The storage client returns a List<FileObject> on success; errors throw.
      try {
        await storage.from(bucket).remove([path]);
      } catch (storageErr) {
        debugPrint('Storage remove error: $storageErr');
      }
    } catch (e) {
      debugPrint('Error deleting storage file: $e');
    }
  }

  Future<void> _toggleUserBan(String userId, bool currentlyBanned) async {
    try {
      final newStatus = !currentlyBanned;
      await Supabase.instance.client.from('profiles').update({'is_banned': newStatus}).eq('user_id', userId);
      if (mounted) {
        setState(() { _usersFuture = _fetchUsers(); });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newStatus ? 'User banned' : 'User unbanned')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating user: $e')));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Community', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [Tab(text: 'Posts'), Tab(text: 'Media'), Tab(text: 'Users')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Posts (streamed, reuse Post model UI with admin controls)
          StreamBuilder<List<Post>>(
            stream: _postsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final posts = snapshot.data ?? [];
              if (posts.isEmpty) return const Center(child: Text('No posts found'));
              return ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
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
                                  : const AssetImage("assets/images/profile_avatar.png") as ImageProvider,
                              radius: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${post.user.firstName ?? ''} ${post.user.lastName ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('@${post.user.firstName?.toLowerCase() ?? ''}', style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'delete') {
                                  final ok = await showDialog<bool>(context: context, builder: (dctx) => AlertDialog(
                                    title: const Text('Delete post?'),
                                    content: const Text('This will permanently remove the post.'),
                                    actions: [TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(dctx, true), child: const Text('Delete'))],
                                  ));
                                  if (ok == true) _deletePost(post.id);
                                } else if (v == 'remove_image') {
                                  final ok = await showDialog<bool>(context: context, builder: (dctx) => AlertDialog(
                                    title: const Text('Remove image?'),
                                    content: const Text('This will remove the image from the post.'),
                                    actions: [TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(dctx, true), child: const Text('Remove'))],
                                  ));
                                  if (ok == true) _removePostImage(post.id);
                                } else if (v == 'ban') {
                                  final ok = await showDialog<bool>(context: context, builder: (dctx) => AlertDialog(
                                    title: const Text('Ban user?'),
                                    content: const Text('Ban this user from the platform?'),
                                    actions: [TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(dctx, true), child: const Text('Ban'))],
                                  ));
                                  if (ok == true) _toggleUserBan(post.user.userId, false);
                                }
                              },
                              itemBuilder: (ctx) => <PopupMenuEntry<String>>[
                                const PopupMenuItem(value: 'delete', child: Text('Delete Post')),
                                if (post.imageUrl != null) const PopupMenuItem(value: 'remove_image', child: Text('Remove Image')),
                                const PopupMenuItem(value: 'ban', child: Text('Ban User')),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(post.content, style: const TextStyle(fontSize: 16)),
                        if (post.imageUrl != null) ...[
                          const SizedBox(height: 10),
                          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(post.imageUrl!, fit: BoxFit.cover)),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              IconButton(icon: const Icon(Icons.comment, color: Colors.grey), onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => CommentsScreen(postId: post.id)));
                              }),
                              const SizedBox(width: 5),
                              Text(post.commentCount.toString()),
                            ]),
                            LikeButton(post: post),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),

          // Media
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _mediaFuture,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final media = snap.data ?? [];
              if (media.isEmpty) return const Center(child: Text('No media entries found'));
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: media.length,
                itemBuilder: (c, i) {
                  final m = media[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: m['url'] != null ? Image.network(m['url'], width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)) : const Icon(Icons.broken_image),
                      title: Text(m['title'] ?? 'Media'),
                      subtitle: Text('Owner: ${m['owner_id'] ?? m['user_id'] ?? 'unknown'}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final ok = await showDialog<bool>(context: context, builder: (dctx) => AlertDialog(
                            title: const Text('Delete media?'),
                            content: const Text('This will remove the media entry (file may remain in storage).'),
                            actions: [TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(dctx, true), child: const Text('Delete'))],
                          ));
                          if (ok == true) _deleteMedia(m['id'].toString());
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // Users
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _usersFuture,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final users = snap.data ?? [];
              if (users.isEmpty) return const Center(child: Text('No users found'));
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: users.length,
                itemBuilder: (c, i) {
                  final u = users[i];
                  final banned = u['is_banned'] == true;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary,
                        foregroundImage: (u['avatar_url'] ?? u['photo_url']) != null ? NetworkImage((u['avatar_url'] ?? u['photo_url']) as String) : null,
                        child: (u['avatar_url'] ?? u['photo_url']) == null ? const Icon(Icons.person, color: Colors.white) : null,
                      ),
                      title: Text('${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim().isNotEmpty ? '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}' : (u['email'] ?? 'User')),
                      subtitle: Text('Role: ${u['role'] ?? 'N/A'} • ${u['email'] ?? ''}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(banned ? Icons.lock_open : Icons.lock, color: banned ? Colors.red : Colors.green),
                            onPressed: () async {
                              final ok = await showDialog<bool>(context: context, builder: (dctx) => AlertDialog(
                                title: Text(banned ? 'Unban user?' : 'Ban user?'),
                                content: Text(banned ? 'Unban this user?' : 'Ban this user from the platform?'),
                                actions: [TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(dctx, true), child: const Text('Yes'))],
                              ));
                              if (ok == true) _toggleUserBan(u['user_id'].toString(), banned);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
