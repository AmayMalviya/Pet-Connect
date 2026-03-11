import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/theme/app_theme.dart';

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

      // Mark as read in background
      final unreadIds = _notifications
          .where((n) => n['is_read'] != true)
          .map((n) => n['id'])
          .toList();
          
      if (unreadIds.isNotEmpty) {
        Supabase.instance.client
            .from('notifications')
            .update({'is_read': true})
            .inFilter('id', unreadIds)
            .then((_) => debugPrint('Marked notifications as read'))
            .catchError((e) => debugPrint('Error marking read: $e'));
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  IconData _getIconForType(String? type) {
    if (type == null) return Icons.notifications;
    switch (type.toLowerCase()) {
      case 'adoption':
        return Icons.pets;
      case 'system':
        return Icons.info_outline;
      case 'warning':
        return Icons.warning_amber;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String? type) {
    if (type == null) return AppColors.primary;
    switch (type.toLowerCase()) {
      case 'adoption':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'system':
        return Colors.blue;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
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
                      Text('No notifications yet', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      final isRead = n['is_read'] == true;
                      final date = DateTime.tryParse(n['created_at'] ?? '')?.toLocal();
                      
                      return Container(
                        color: isRead ? Colors.transparent : AppColors.primary.withOpacity(0.05),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: _getColorForType(n['type'] as String?).withOpacity(0.1),
                            child: Icon(_getIconForType(n['type'] as String?), color: _getColorForType(n['type'] as String?)),
                          ),
                          title: Text(
                            n['title'] ?? 'Notification',
                            style: GoogleFonts.poppins(
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                n['body'] ?? '',
                                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                              ),
                              if (date != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
