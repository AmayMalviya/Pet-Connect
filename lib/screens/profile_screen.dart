import 'package:flutter/material.dart';
import '../models/profile_args.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatelessWidget {
  static const routeName = '/profile';
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as ProfileArgs?;
    final name = args?.name ?? "Guest";
    final email = args?.email ?? "guest@example.com";
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Profile"),
        actions: [
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: "Favs"),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: ListView(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  child: Text((name.isEmpty ? "G" : name[0]).toUpperCase(),
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Olá, $name", style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    Text(email, style: t.bodyMedium?.copyWith(color: Colors.black54)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 16),
            _SectionTitle("Albums"),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, i) => Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: i.isEven ? AppColors.accent : AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemCount: 6,
              ),
            ),
            const SizedBox(height: 16),
            _SectionTitle("Popular this week"),
            _FeatureTile(icon: Icons.calendar_month_rounded, title: "Appointments", subtitle: "Track your visits"),
            const SizedBox(height: 12),
            _FeatureTile(icon: Icons.map_rounded, title: "Nearby Services", subtitle: "Parks and stores"),
            const SizedBox(height: 12),
            _FeatureTile(icon: Icons.settings_rounded, title: "Settings", subtitle: "Notifications & privacy"),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.accent.withOpacity(0.18),
            child: Icon(icon, color: AppColors.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
