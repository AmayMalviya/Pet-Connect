import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/theme/app_theme.dart';

class ManageProfilesScreen extends StatefulWidget {
  static const routeName = '/manage-profiles';

  const ManageProfilesScreen({super.key});

  @override
  State<ManageProfilesScreen> createState() => _ManageProfilesScreenState();
}

class _ManageProfilesScreenState extends State<ManageProfilesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _profilesFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _profilesFuture = _fetchProfiles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchProfiles() async {
    final supabase = Supabase.instance.client;
    final response = await supabase.from('profiles').select('*').order('created_at', ascending: false);
    return response;
  }

  /// Fetch pets for a user (for both pet owners and shelters)
  Future<List<Map<String, dynamic>>> _fetchUserPets(String userId, String userRole) async {
    try {
      late List<Map<String, dynamic>> pets;
      if (userRole == 'Pet Owner') {
        pets = await Supabase.instance.client
            .from('pets')
            .select('*')
            .eq('owner_id', userId)
            .order('created_at', ascending: false);
      } else {
        pets = await Supabase.instance.client
            .from('animals_for_adoption')
            .select('*')
            .eq('shelter_id', userId)
            .order('created_at', ascending: false);
      }
      return pets;
    } catch (e) {
      debugPrint('Error fetching pets: $e');
      return [];
    }
  }

  /// Toggle ban status for a user
  Future<void> _toggleBanStatus(String userId, bool currentlyBanned) async {
    try {
      final newBanStatus = !currentlyBanned;
      await Supabase.instance.client
          .from('profiles')
          .update({'is_banned': newBanStatus})
          .eq('user_id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newBanStatus ? 'User banned successfully!' : 'User unbanned successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _profilesFuture = _fetchProfiles();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating ban status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Toggle restriction status for a user
  Future<void> _toggleRestrictStatus(String userId, bool currentlyRestricted) async {
    try {
      final newStatus = !currentlyRestricted;
      await Supabase.instance.client
          .from('profiles')
          .update({'is_restricted': newStatus})
          .eq('user_id', userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? 'User restricted successfully!' : 'User restriction removed!'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _profilesFuture = _fetchProfiles());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating restriction status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Manually verify a user
  Future<void> _verifyUserManually(String userId) async {
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({
            'kyc_verified': true,
            'kyc_status': 'approved',
          })
          .eq('user_id', userId);

      // Also update shelter_kyc status if it exists
      await Supabase.instance.client
          .from('shelter_kyc')
          .update({'status': 'approved'})
          .eq('user_id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User verified manually!'), backgroundColor: Colors.green),
        );
        setState(() => _profilesFuture = _fetchProfiles());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error verifying user: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _sendWarning(String userId, String userName) {
    final TextEditingController warningController = TextEditingController();
    showDialog(
      context: context,
      builder: (wCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Warn $userName', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter a warning message for this user:', style: GoogleFonts.poppins(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: warningController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Warning reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(wCtx), child: Text('Cancel', style: GoogleFonts.poppins())),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(wCtx);
              // In a real implementation this would store a warning record in DB
              // For now log and show confirmation
              debugPrint('Warning sent to $userId: ${warningController.text}');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Warning issued to user.'), backgroundColor: Colors.amber),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            child: Text('Send Warning', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showProfileDetails(Map<String, dynamic> profile) {
    final isBanned = profile['is_banned'] == true;
    final userRole = profile['role'] ?? 'N/A';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with profile image and ban status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary,
                      foregroundImage: _getProfileImageUrl(profile) != null ? NetworkImage(_getProfileImageUrl(profile)!) : null,
                      child: _getProfileImageUrl(profile) == null
                          ? Icon(profile['role'] == 'Pet Owner' ? Icons.person : Icons.home, color: Colors.white, size: 28)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim(),
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            profile['email'] ?? 'No email',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    if (isBanned)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'BANNED',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.red[900]),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Profile details
                _buildDetailRow('Role', userRole),
                _buildDetailRow('Phone', profile['phone'] ?? 'N/A'),
                _buildDetailRow('City', profile['city'] ?? 'N/A'),
                _buildDetailRow('State', profile['state'] ?? 'N/A'),
                _buildDetailRow('Country', profile['country'] ?? 'N/A'),
                _buildDetailRow('KYC Verified', (profile['kyc_verified'] == true) ? '✓ Yes' : '✗ No'),
                _buildDetailRow('Joined', _formatDate(profile['created_at'] ?? '')),
                const SizedBox(height: 16),

                // Pets Section
                if (userRole == 'Pet Owner' || userRole == 'Shelter')
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchUserPets(profile['user_id'], userRole),
                    builder: (ctx, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        return _buildPetsSection(snapshot.data!, userRole);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                const SizedBox(height: 16),

                // Action buttons - grid layout for 4 actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _toggleBanStatus(profile['user_id'], isBanned);
                              Navigator.pop(ctx);
                            },
                            icon: Icon(isBanned ? Icons.lock_open : Icons.lock, size: 16),
                            label: Text(isBanned ? 'Unban' : 'Ban', style: GoogleFonts.poppins(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isBanned ? Colors.green : Colors.red,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 40),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final isRestricted = profile['is_restricted'] == true;
                              _toggleRestrictStatus(profile['user_id'], isRestricted);
                              Navigator.pop(ctx);
                            },
                            icon: Icon(
                              (profile['is_restricted'] == true) ? Icons.radio_button_checked : Icons.do_not_disturb,
                              size: 16,
                            ),
                            label: Text(
                              (profile['is_restricted'] == true) ? 'Unrestrict' : 'Restrict',
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 40),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final name = '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim();
                              _sendWarning(profile['user_id'], name.isNotEmpty ? name : 'User');
                            },
                            icon: const Icon(Icons.warning_amber, size: 16),
                            label: Text('Warn', style: GoogleFonts.poppins(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber[700],
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 40),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close, size: 16),
                            label: Text('Close', style: GoogleFonts.poppins(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 40),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if ((userRole == 'Shelter' || userRole == 'Shelter Owner') && 
                        profile['kyc_verified'] != true && 
                        profile['kyc_status'] != 'verified' && 
                        profile['kyc_status'] != 'approved') ...[
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          _verifyUserManually(profile['user_id']);
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.verified_user, size: 16),
                        label: Text('Verify Manually', style: GoogleFonts.poppins(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 40),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPetsSection(List<Map<String, dynamic>> pets, String userRole) {
    final title = userRole == 'Pet Owner' ? 'My Pets' : 'Shelter Pets';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (${pets.length})',
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pets.length,
          itemBuilder: (ctx, idx) {
            final pet = pets[idx];
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          pet['name'] ?? 'Unknown Pet',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (pet['age'] != null)
                        Text(
                          'Age: ${pet['age']}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pet['species'] ?? 'N/A'} • ${pet['breed'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  if (pet['description'] != null && (pet['description'] as String).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        pet['description'],
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Profiles', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Pet Owners'),
            Tab(text: 'Shelters'),
          ],
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _profilesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No profiles found.'));
          }

          final allProfiles = snapshot.data!;

          // Filter profiles by role
          final petOwners = allProfiles.where((p) => p['role'] == 'Pet Owner').toList();
          final shelters = allProfiles.where((p) => p['role'] == 'Shelter' || p['role'] == 'Shelter Owner').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              // Pet Owners tab
              _buildProfileList(petOwners, 'No Pet Owners'),
              // Shelters tab
              _buildProfileList(shelters, 'No Shelters'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileList(List<Map<String, dynamic>> profiles, String emptyMessage) {
    if (profiles.isEmpty) {
      return Center(child: Text(emptyMessage, style: GoogleFonts.poppins(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        final isBanned = profile['is_banned'] == true;
        final fullName = '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim();
        final isVerified = profile['kyc_verified'] == true || profile['kyc_status'] == 'verified' || profile['kyc_status'] == 'approved';

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isBanned ? Colors.red[50] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: isBanned ? Colors.red.withOpacity(0.3) : Colors.grey[200]!),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showProfileDetails(profile),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                          ),
                          child: CircleAvatar(
                            backgroundColor: Colors.grey[100],
                            foregroundImage: _getProfileImageUrl(profile) != null ? NetworkImage(_getProfileImageUrl(profile)!) : null,
                            child: _getProfileImageUrl(profile) == null
                                ? Icon(
                                    profile['role'] == 'Pet Owner' ? Icons.person : Icons.home,
                                    color: AppColors.primary,
                                  )
                                : null,
                          ),
                        ),
                        if (isBanned)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.block, size: 10, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  fullName.isNotEmpty ? fullName : 'User ID: ${profile['user_id'].toString().substring(0, 8)}...',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: AppColors.textDark,
                                    decoration: isBanned ? TextDecoration.lineThrough : null,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.verified, color: Colors.blue, size: 16),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              profile['role'] ?? 'N/A',
                              style: GoogleFonts.poppins(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    isBanned
                        ? const Icon(Icons.lock, color: Colors.red, size: 20)
                        : Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Try a few common profile image fields and return the first non-null url
  String? _getProfileImageUrl(Map<String, dynamic> profile) {
    final candidates = [
      'avatar_url',
      'avatar',
      'photo_url',
      'profile_picture',
      'image_url',
      'photo',
    ];
    for (final key in candidates) {
      if (profile.containsKey(key) && profile[key] != null && (profile[key] as String).isNotEmpty) {
        return profile[key] as String;
      }
    }
    return null;
  }
}
