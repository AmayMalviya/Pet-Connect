import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/screens/admin/manage_profiles_screen.dart';
import 'package:pet_connect_app/screens/admin/admin_kyc_approval_screen.dart';
import 'package:pet_connect_app/screens/login_screen.dart';
import 'package:pet_connect_app/screens/admin/manage_community_screen.dart';
import 'package:pet_connect_app/screens/admin/admin_analytics_screen.dart';
import 'package:pet_connect_app/widgets/notification_bell.dart';
import 'package:pet_connect_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardScreen extends StatelessWidget {
  static const routeName = '/admin-dashboard';
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          const NotificationBell(iconColor: Colors.black87),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  LoginScreen.routeName,
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            _buildAdminTaskCard(
              context,
              icon: Icons.people_alt_outlined,
              title: 'Manage Profiles',
              color: Colors.blueAccent,
              onTap: () {
                Navigator.pushNamed(context, ManageProfilesScreen.routeName);
              },
            ),
            _buildAdminTaskCard(
              context,
              icon: Icons.verified_user,
              title: 'KYC Approvals',
              color: Colors.orangeAccent,
              onTap: () {
                Navigator.pushNamed(context, AdminKycApprovalScreen.routeName);
              },
            ),
            _buildAdminTaskCard(
              context,
              icon: Icons.groups,
              title: 'Manage Community',
              color: Colors.green,
              onTap: () {
                Navigator.pushNamed(context, ManageCommunityScreen.routeName);
              },
            ),
            _buildAdminTaskCard(
              context,
              icon: Icons.bar_chart_rounded,
              title: 'App Analytics',
              color: Colors.purpleAccent,
              onTap: () {
                Navigator.pushNamed(context, AdminAnalyticsScreen.routeName);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminTaskCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 36, color: color),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
