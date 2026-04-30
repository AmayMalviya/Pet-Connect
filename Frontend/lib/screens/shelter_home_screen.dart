import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/screens/shelter/manage_pets_screen.dart';
import 'package:pet_connect_app/screens/shelter_adoption_requests_screen.dart';
import 'package:pet_connect_app/screens/shelter_profile_screen.dart';
import 'package:pet_connect_app/screens/shelter/shelter_analytics_screen.dart';
import 'package:pet_connect_app/screens/add_edit_pet_screen.dart';
import 'package:pet_connect_app/screens/kyc_screen.dart';
import 'package:pet_connect_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Used both:
///  - as a tab body inside MainScreen (no Scaffold needed there)
///  - as a standalone route via /shelter-home (wraps itself in a Scaffold)
class ShelterHomeScreen extends StatelessWidget {
  static const routeName = '/shelter-home';

  const ShelterHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Detect whether we're already inside a Scaffold (tab mode) or not.
    // When used as a tab, MainScreen provides the Scaffold + AppBar.
    // When navigated to directly, we wrap ourselves.
    final isNested = Scaffold.maybeOf(context) != null;

    final body = _ShelterHomeBody();

    if (isNested) return body;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text('Shelter Hub',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: body,
    );
  }
}

// ── Body (shared between tab and standalone) ──────────────────────────────────

class _ShelterHomeBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('profiles')
          .stream(primaryKey: ['user_id']).eq(
              'user_id', Supabase.instance.client.auth.currentUser!.id),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── KYC banner (only when unverified) ────────────────────────
            if (!kycVerified) _KycBanner(),

            // ── Scrollable content (dimmed + non-interactive when locked) ─
            Expanded(
              child: AbsorbPointer(
                absorbing: !kycVerified,
                child: AnimatedOpacity(
                  opacity: kycVerified ? 1.0 : 0.45,
                  duration: const Duration(milliseconds: 300),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // ── Hero card ───────────────────────────────────────
                      _HeroCard(kycVerified: kycVerified),

                      const SizedBox(height: 24),

                      // ── Section title ───────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Explore Tools',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── 2×1 grid of quick-action cards ─────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _QuickCard(
                                title: 'Manage Pets',
                                subtitle: 'View & update rescues',
                                icon: Icons.pets,
                                color: Colors.blue.shade600,
                                onTap: () => Navigator.pushNamed(
                                    context, ManagePetsScreen.routeName),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _QuickCard(
                                title: 'Adoptions',
                                subtitle: 'Review requests',
                                icon: Icons.volunteer_activism_outlined,
                                color: Colors.pink.shade500,
                                onTap: () => Navigator.pushNamed(context,
                                    ShelterAdoptionRequestsScreen.routeName),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Wide cards ──────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _WideCard(
                          title: 'Analytics',
                          subtitle: "Track your shelter's performance",
                          icon: Icons.analytics_outlined,
                          color: Colors.deepPurple.shade500,
                          onTap: () => Navigator.pushNamed(
                              context, ShelterAnalyticsScreen.routeName),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _WideCard(
                          title: 'Shelter Profile',
                          subtitle: 'Update details & contacts',
                          icon: Icons.store_outlined,
                          color: Colors.teal.shade500,
                          onTap: () => Navigator.pushNamed(
                              context, ShelterProfileScreen.routeName),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Hero card ─────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final bool kycVerified;
  const _HeroCard({required this.kycVerified});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 20,
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
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage your rescues\n& connect with adopters.',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.88),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEditPetScreen()),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text('Add a Pet',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          // Decorative background icon
          Positioned(
            right: -12,
            bottom: -24,
            child: Opacity(
              opacity: 0.12,
              child: const Icon(Icons.pets, size: 120, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Square quick-action card ──────────────────────────────────────────────────

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      color: color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Wide card ─────────────────────────────────────────────────────────────────

class _WideCard extends StatelessWidget {
  const _WideCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: _CardShell(
        color: color,
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Shared card shell ─────────────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.color,
    required this.onTap,
    required this.child,
  });

  final Color color;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.72)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.28),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ── KYC banner ────────────────────────────────────────────────────────────────

class _KycBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.orange.shade700,
      elevation: 0,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, KycScreen.routeName),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Features locked — tap to complete KYC verification.',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}