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
      final response = await Supabase.instance.client
          .from('profiles')
          .update({
            'kyc_verified': true,
            'kyc_status': 'completed',
          })
          .eq('user_id', userId)
          .select();

      if (response.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not update — check Supabase RLS policies for the profiles table.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Optionally update shelter_kyc if a row exists
      try {
        await Supabase.instance.client
            .from('shelter_kyc')
            .update({'status': 'approved'})
            .eq('user_id', userId);
      } catch (_) {
        // No shelter_kyc row — fine
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User verified successfully!'), backgroundColor: Colors.green),
        );
        final refreshed = _fetchProfiles();
        setState(() {
          _profilesFuture = refreshed;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Manage Profiles', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              final refreshed = _fetchProfiles();
              setState(() {
                _profilesFuture = refreshed;
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
              unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14),
              tabs: const [
                Tab(text: 'Pet Owners'),
                Tab(text: 'Shelters'),
              ],
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _profilesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text('Error loading profiles', style: GoogleFonts.poppins(color: Colors.red)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      final refreshed = _fetchProfiles();
                      setState(() {
                        _profilesFuture = refreshed;
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text('Retry', style: GoogleFonts.poppins()),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No profiles found.', style: GoogleFonts.poppins(color: Colors.grey)));
          }

          final allProfiles = snapshot.data!;
          final petOwners = allProfiles.where((p) => p['role'] == 'Pet Owner').toList();
          final shelters = allProfiles.where((p) => p['role'] == 'Shelter' || p['role'] == 'Shelter Owner').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildProfileList(petOwners, 'No Pet Owners found'),
              _buildProfileList(shelters, 'No Shelters found'),
            ],
          );
        },
      ),
    );
  }


  Widget _buildProfileList(List<Map<String, dynamic>> profiles, String emptyMessage) {
    if (profiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(emptyMessage, style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        final isBanned = profile['is_banned'] == true;
        final isRestricted = profile['is_restricted'] == true;
        final kycStatus = profile['kyc_status'] as String? ?? '';
        final isVerified = profile['kyc_verified'] == true ||
            kycStatus == 'completed' ||
            kycStatus == 'verified' ||
            kycStatus == 'approved';
        final fullName = '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim();
        final location = [profile['city'], profile['state']]
            .where((s) => s != null && (s as String).isNotEmpty)
            .join(', ');

        // Determine KYC badge color and label
        Color kycColor;
        String kycLabel;
        if (isVerified) {
          kycColor = Colors.green;
          kycLabel = 'Verified';
        } else if (kycStatus == 'pending') {
          kycColor = Colors.orange;
          kycLabel = 'Pending';
        } else if (kycStatus == 'rejected') {
          kycColor = Colors.red;
          kycLabel = 'Rejected';
        } else {
          kycColor = Colors.grey;
          kycLabel = 'Unverified';
        }

        return GestureDetector(
          onTap: () => _showProfileDetails(profile),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: isBanned ? Colors.red[50] : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isBanned
                    ? Colors.red.withOpacity(0.25)
                    : isRestricted
                        ? Colors.orange.withOpacity(0.3)
                        : Colors.grey[200]!,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: avatar + name + status badges
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar with status dot
                      Stack(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.15),
                                  AppColors.accent.withOpacity(0.15),
                                ],
                              ),
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.transparent,
                              foregroundImage: _getProfileImageUrl(profile) != null
                                  ? NetworkImage(_getProfileImageUrl(profile)!)
                                  : null,
                              child: _getProfileImageUrl(profile) == null
                                  ? Icon(
                                      profile['role'] == 'Pet Owner' ? Icons.person_rounded : Icons.home_work_rounded,
                                      color: AppColors.primary,
                                      size: 26,
                                    )
                                  : null,
                            ),
                          ),
                          if (isVerified)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(3),
                                child: const Icon(Icons.check, size: 9, color: Colors.white),
                              ),
                            )
                          else if (isBanned)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(3),
                                child: const Icon(Icons.block, size: 9, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Name + email + badges
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    fullName.isNotEmpty
                                        ? fullName
                                        : 'Unnamed User',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: isBanned ? Colors.red[700] : AppColors.textDark,
                                      decoration: isBanned ? TextDecoration.lineThrough : null,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isVerified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified_rounded, color: Colors.blue, size: 15),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile['email'] ?? 'No email',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // Status chips row
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                // Role chip
                                _buildChip(
                                  profile['role'] ?? 'N/A',
                                  AppColors.primary.withOpacity(0.12),
                                  AppColors.primary,
                                ),
                                // KYC chip
                                _buildChip(
                                  kycLabel,
                                  kycColor.withOpacity(0.12),
                                  kycColor,
                                ),
                                // Banned chip
                                if (isBanned)
                                  _buildChip('Banned', Colors.red[50]!, Colors.red[700]!),
                                // Restricted chip
                                if (isRestricted && !isBanned)
                                  _buildChip('Restricted', Colors.orange[50]!, Colors.orange[700]!),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Divider
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1, thickness: 0.8),
                    const SizedBox(height: 10),
                    // Location + quick actions row
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location,
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 10),
                  const Divider(height: 1, thickness: 0.8),
                  const SizedBox(height: 8),

                  // Quick action row
                  Row(
                    children: [
                      // Ban / Unban quick button
                      _buildQuickAction(
                        icon: isBanned ? Icons.lock_open_rounded : Icons.lock_rounded,
                        label: isBanned ? 'Unban' : 'Ban',
                        color: isBanned ? Colors.green[700]! : Colors.red[600]!,
                        bgColor: isBanned ? Colors.green[50]! : Colors.red[50]!,
                        onTap: () => _toggleBanStatus(profile['user_id'], isBanned),
                      ),
                      const SizedBox(width: 8),
                      // Restrict quick button
                      _buildQuickAction(
                        icon: isRestricted ? Icons.remove_circle_outline : Icons.do_not_disturb_on_outlined,
                        label: isRestricted ? 'Unrestrict' : 'Restrict',
                        color: Colors.orange[700]!,
                        bgColor: Colors.orange[50]!,
                        onTap: () => _toggleRestrictStatus(profile['user_id'], isRestricted),
                      ),
                      const SizedBox(width: 8),
                      // Verify quick button (only for unverified shelters)
                      if (!isVerified && (profile['role'] == 'Shelter' || profile['role'] == 'Shelter Owner'))
                        _buildQuickAction(
                          icon: Icons.verified_user_rounded,
                          label: 'Verify',
                          color: Colors.blue[700]!,
                          bgColor: Colors.blue[50]!,
                          onTap: () => _verifyUserManually(profile['user_id']),
                        ),
                      const Spacer(),
                      // View details arrow
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 10, color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 11, color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
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
