import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/screens/shelter/manage_pets_screen.dart';
import 'package:pet_connect_app/screens/shelter_adoption_requests_screen.dart';
import 'package:pet_connect_app/screens/shelter_profile_screen.dart';
import 'package:pet_connect_app/screens/shelter/shelter_analytics_screen.dart';
import 'package:pet_connect_app/screens/add_edit_pet_screen.dart';
import 'package:pet_connect_app/screens/kyc_screen.dart';
import 'package:pet_connect_app/theme/app_theme.dart';
import 'package:pet_connect_app/widgets/notification_bell.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShelterHomeScreen extends StatelessWidget {
  static const routeName = '/shelter-home';

  const ShelterHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Home', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        actions: [const NotificationBell()],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('profiles')
            .stream(primaryKey: ['user_id'])
            .eq('user_id', Supabase.instance.client.auth.currentUser!.id),
        builder: (context, snapshot) {
          final profile = (snapshot.hasData && snapshot.data!.isNotEmpty)
              ? snapshot.data!.first
              : null;
          final kycStatus = profile?['kyc_status'] as String? ?? '';
          final kycVerified = profile?['kyc_verified'] == true ||
              kycStatus == 'completed' ||
              kycStatus == 'verified' ||
              kycStatus == 'approved';

          return Column(
            children: [
              // ── Sticky KYC banner ──────────────────────────────────────
              if (!kycVerified) _KycBanner(),

              // ── Content — fully blocked when unverified ────────────────
              Expanded(
                child: AbsorbPointer(
                  absorbing: !kycVerified,
                  child: Opacity(
                    opacity: kycVerified ? 1.0 : 0.45,
                    child: CustomScrollView(
                      slivers: [
                        // Hero banner
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Shelter Hub',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Manage your rescues\n& connect with adopters.',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton(
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => const AddEditPetScreen()),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: AppColors.primary,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: Text('Add a Pet',
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  right: -20,
                                  bottom: -40,
                                  child: Opacity(
                                    opacity: 0.15,
                                    child: const Icon(Icons.pets,
                                        size: 140, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Search bar
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search for pets, requests...',
                                  hintStyle:
                                      GoogleFonts.poppins(color: Colors.grey[400]),
                                  prefixIcon:
                                      const Icon(Icons.search, color: Colors.grey),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 16)),

                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            child: Text(
                              'Explore Tools',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        ),

                        // Tools grid
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          sliver: SliverGrid.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.85,
                            children: [
                              _PremiumShelterCard(
                                title: 'Manage Pets',
                                subtitle: 'View and update rescues',
                                icon: Icons.pets,
                                color: Colors.blue.shade600,
                                onTap: () => Navigator.pushNamed(
                                    context, ManagePetsScreen.routeName),
                              ),
                              _PremiumShelterCard(
                                title: 'Adoption Requests',
                                subtitle: 'Review incoming requests',
                                icon: Icons.volunteer_activism_outlined,
                                color: Colors.pink.shade500,
                                onTap: () => Navigator.pushNamed(
                                    context,
                                    ShelterAdoptionRequestsScreen.routeName),
                              ),
                            ],
                          ),
                        ),

                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: _PremiumShelterCard(
                              title: 'Analytics',
                              subtitle: "Track your shelter's performance",
                              icon: Icons.analytics_outlined,
                              color: Colors.deepPurple.shade500,
                              isWide: true,
                              onTap: () => Navigator.pushNamed(
                                  context, ShelterAnalyticsScreen.routeName),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                            child: _PremiumShelterCard(
                              title: 'Manage Profile',
                              subtitle: 'Update shelter details and contacts',
                              icon: Icons.person_outline,
                              color: Colors.teal.shade500,
                              isWide: true,
                              onTap: () => Navigator.pushNamed(
                                  context, ShelterProfileScreen.routeName),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Sticky KYC banner ─────────────────────────────────────────────────────────

class _KycBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      color: Colors.orange.shade700,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, KycScreen.routeName),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Features Locked — KYC Required',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Tap here to complete verification and unlock all tools.',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Card widget ───────────────────────────────────────────────────────────────

class _PremiumShelterCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isWide;

  const _PremiumShelterCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    final gradientEnd = color.withOpacity(0.7);

    return Container(
      height: isWide ? 110 : null,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: isWide
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_ios,
                            color: Colors.white, size: 14),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}