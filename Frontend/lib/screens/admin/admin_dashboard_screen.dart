import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/screens/admin/manage_profiles_screen.dart';
import 'package:pet_connect_app/screens/admin/admin_kyc_approval_screen.dart';
import 'package:pet_connect_app/screens/login_screen.dart';
import 'package:pet_connect_app/screens/admin/manage_community_screen.dart';
import 'package:pet_connect_app/screens/admin/admin_analytics_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardScreen extends StatelessWidget {
  static const routeName = '/admin-dashboard';
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (Route<dynamic> route) => false,
              );
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
              onTap: () {
                Navigator.pushNamed(context, ManageProfilesScreen.routeName);
              },
            ),
            _buildAdminTaskCard(
              context,
              icon: Icons.verified_user,
              title: 'KYC Approvals',
              onTap: () {
                Navigator.pushNamed(context, AdminKycApprovalScreen.routeName);
              },
            ),
            _buildAdminTaskCard(
              context,
              icon: Icons.groups,
              title: 'Manage Community',
              onTap: () {
                Navigator.pushNamed(context, ManageCommunityScreen.routeName);
              },
            ),
            _buildAdminTaskCard(
              context,
              icon: Icons.bar_chart_rounded,
              title: 'App Analytics',
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
    required VoidCallback onTap,
  }) {
    final primaryColor = Theme.of(context).primaryColor;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: primaryColor.withOpacity(0.2),
        highlightColor: primaryColor.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.9),
                primaryColor.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
  child: Padding(
    padding: const EdgeInsets.all(20.0),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            padding: const EdgeInsets.all(16),
            child: Icon(icon, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  ),
),
        ),
      ),
    );
  }
}
