import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/theme/app_theme.dart';
import 'package:pet_connect_app/screens/shelter_adoption_requests_screen.dart';

class NotificationsScreen extends StatefulWidget {
  static const routeName = '/notifications';
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('notifications')
          .select('*')
          .eq('recipient_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        _notifications = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markOneRead(String id) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
      setState(() {
        final idx = _notifications.indexWhere((n) => n['id'] == id);
        if (idx != -1) _notifications[idx]['is_read'] = true;
      });
    } catch (e) {
      debugPrint('Error marking notification read: $e');
    }
  }

  Future<void> _markAllRead() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('recipient_id', userId)
          .eq('is_read', false);
      setState(() {
        for (final n in _notifications) {
          n['is_read'] = true;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('All notifications marked as read.')));
      }
    } catch (e) {
      debugPrint('Error marking all read: $e');
    }
  }

  void _onNotificationTap(Map<String, dynamic> n, String? userRole) {
    if (n['is_read'] != true) {
      _markOneRead(n['id'] as String);
    }

    final type = (n['type'] as String? ?? '').toLowerCase();

    if (type == 'adoption') {
      // Adoption-type: shelter should see their adoption requests
      if (userRole == 'Shelter' || userRole == 'Shelter Owner') {
        Navigator.pushNamed(context, ShelterAdoptionRequestsScreen.routeName);
      }
      // For pet owners, adoption notifications are from shelter responses — no deep link needed yet
    }
    // System/warning types: no deep link, just mark read
  }

  IconData _getIconForType(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'adoption': return Icons.pets;
      case 'warning': return Icons.warning_amber;
      case 'system': return Icons.info_outline;
      default: return Icons.notifications;
    }
  }

  Color _getColorForType(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'adoption': return Colors.green;
      case 'warning': return Colors.orange;
      case 'system': return Colors.blue;
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n['is_read'] != true).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text('Read All', style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No notifications yet',
                          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: FutureBuilder<Map<String, dynamic>?>(
                    future: _fetchUserProfile(),
                    builder: (context, snapshot) {
                      final userRole = snapshot.data?['role'] as String?;
                      return ListView.separated(
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final n = _notifications[index];
                          final isRead = n['is_read'] == true;
                          final date = DateTime.tryParse(n['created_at'] ?? '')?.toLocal();
                          final type = n['type'] as String?;

                          return InkWell(
                            onTap: () => _onNotificationTap(n, userRole),
                            child: Container(
                              color: isRead ? Colors.transparent : AppColors.primary.withOpacity(0.05),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: _getColorForType(type).withOpacity(0.12),
                                    child: Icon(_getIconForType(type), color: _getColorForType(type)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                n['title'] ?? 'Notification',
                                                style: GoogleFonts.poppins(
                                                  fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            if (!isRead)
                                              Container(
                                                width: 8, height: 8,
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          n['body'] ?? '',
                                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                                        ),
                                        if (date != null) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            '${date.day}/${date.month}/${date.year}  ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }

  Future<Map<String, dynamic>?> _fetchUserProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;
    return await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('user_id', userId)
        .maybeSingle();
  }
}
