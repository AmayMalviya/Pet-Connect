import 'package:flutter/material.dart';
import 'package:pet_connect_app/screens/community_screen.dart';
import 'package:pet_connect_app/screens/main_screen.dart';
import 'package:pet_connect_app/screens/profile_screen.dart';
import 'package:pet_connect_app/screens/services_screen.dart';
import 'package:pet_connect_app/screens/shop_screen.dart';
import 'package:pet_connect_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _userName = 'User';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('first_name, last_name, email')
          .eq('user_id', user.id)
          .maybeSingle();

      if (mounted && profile != null) {
        setState(() {
          _userName = '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim();
          _userEmail = profile['email'] ?? user.email ?? '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_userName),
            accountEmail: Text(_userEmail),
            currentAccountPicture: const CircleAvatar(
              backgroundImage: AssetImage('assets/images/profile_avatar.png'),
            ),
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pushReplacementNamed(context, MainScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Community'),
            onTap: () {
              Navigator.pushReplacementNamed(context, CommunityScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.miscellaneous_services),
            title: const Text('Services'),
            onTap: () {
              Navigator.pushReplacementNamed(context, ServicesScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text('Shop'),
            onTap: () {
              Navigator.pushReplacementNamed(context, ShopScreen.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pushNamed(context, ProfileScreen.routeName);
            },
          ),
        ],
      ),
    );
  }
}
