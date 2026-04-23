import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/theme/app_theme.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  static const routeName = '/admin-analytics';
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  bool _isLoading = true;
  Map<String, int> _userCounts = {};
  int _totalPosts = 0;
  int _totalAdoptionRequests = 0;
  int _pendingAdoptions = 0;
  int _bannedUsers = 0;
  int _restrictedUsers = 0;
  List<Map<String, dynamic>> _recentSignups = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final db = Supabase.instance.client;

      // All profiles
      final profiles = await db.from('profiles').select('role, is_banned, is_restricted, created_at') as List<dynamic>;

      final Map<String, int> userCounts = {};
      int banned = 0;
      int restricted = 0;
      for (final p in profiles) {
        final role = p['role'] as String? ?? 'Unknown';
        userCounts[role] = (userCounts[role] ?? 0) + 1;
        if (p['is_banned'] == true) banned++;
        if (p['is_restricted'] == true) restricted++;
      }

      // Posts
      final posts = await db.from('posts').select('id') as List<dynamic>;

      // Adoption requests
      final adoptions = await db.from('adoption_requests').select('id, status') as List<dynamic>;
      final pendingAdoptions = adoptions.where((a) => a['status'] == 'Pending').length;

      // Recent signups (last 7 days)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
      final recentSignups = await db
          .from('profiles')
          .select('first_name, last_name, role, created_at')
          .gte('created_at', sevenDaysAgo)
          .order('created_at', ascending: false)
          .limit(10) as List<dynamic>;

      setState(() {
        _userCounts = userCounts;
        _totalPosts = posts.length;
        _totalAdoptionRequests = adoptions.length;
        _pendingAdoptions = pendingAdoptions;
        _bannedUsers = banned;
        _restrictedUsers = restricted;
        _recentSignups = recentSignups.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Analytics error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _userCounts.values.fold(0, (a, b) => a + b);
    return Scaffold(
      appBar: AppBar(
        title: Text('App Analytics', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary Cards
                  Text('Overview', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.15,
                    children: [
                      _statCard('Total Users', total.toString(), Icons.people_alt_outlined, AppColors.primary),
                      _statCard('Posts', _totalPosts.toString(), Icons.article_outlined, Colors.blue),
                      _statCard('Adoptions', _totalAdoptionRequests.toString(), Icons.volunteer_activism, Colors.green),
                      _statCard('Pending', _pendingAdoptions.toString(), Icons.hourglass_empty, Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Moderation stats
                  Text('Moderation', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _statCard('Banned', _bannedUsers.toString(), Icons.block, Colors.red)),
                      const SizedBox(width: 12),
                      Expanded(child: _statCard('Restricted', _restrictedUsers.toString(), Icons.do_not_disturb, Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Users by role
                  Text('Users by Role', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...(_userCounts.entries.map((entry) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            entry.value.toString(),
                            style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ))),
                  const SizedBox(height: 20),

                  // Recent sign-ups
                  Text('New Users (Last 7 days)', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_recentSignups.isEmpty)
                    Text('No new sign-ups.', style: GoogleFonts.poppins(color: Colors.grey)),
                  ..._recentSignups.map((u) {
                    final name = '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim();
                    final role = u['role'] as String? ?? 'N/A';
                    final date = DateTime.tryParse(u['created_at'] ?? '')?.toLocal();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.15),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(name.isNotEmpty ? name : 'User', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      subtitle: Text(role, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                      trailing: date != null
                          ? Text(
                              '${date.day}/${date.month}',
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                            )
                          : null,
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.85), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(label, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
