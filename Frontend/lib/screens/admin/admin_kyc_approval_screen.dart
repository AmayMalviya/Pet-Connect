import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/theme/app_theme.dart';

class AdminKycApprovalScreen extends StatefulWidget {
  static const routeName = '/admin-kyc-approval';

  const AdminKycApprovalScreen({super.key});

  @override
  State<AdminKycApprovalScreen> createState() => _AdminKycApprovalScreenState();
}

class _AdminKycApprovalScreenState extends State<AdminKycApprovalScreen> {
  late Future<List<Map<String, dynamic>>> _pendingKycFuture;

  @override
  void initState() {
    super.initState();
    _pendingKycFuture = _fetchPendingKyc();
  }

  /// Fetch pending KYC requests with full details from profiles, kyc_documents, and kyc_personal
  /// Only includes users who have SUBMITTED KYC documents AND personal details (filters out dummy/incomplete submissions)
  Future<List<Map<String, dynamic>>> _fetchPendingKyc() async {
    try {
      // Fetch unverified shelter profiles
      final profiles = await Supabase.instance.client
          .from('profiles')
          .select('*')
          .or('role.eq.Shelter,role.eq.Shelter Owner')
          .eq('kyc_verified', false);

      final List<Map<String, dynamic>> result = [];

      for (var profile in profiles) {
        final userId = profile['user_id'];

        // Fetch the most recent KYC document for this user
        final docs = await Supabase.instance.client
            .from('kyc_documents')
            .select('*')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(1);

        // Fetch the most recent KYC personal details for this user
        final personal = await Supabase.instance.client
            .from('kyc_personal')
            .select('*')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(1);

        // Only include users who have BOTH kyc_documents AND kyc_personal records
        // This filters out unverified users without any submitted KYC data
        if (docs.isNotEmpty && personal.isNotEmpty) {
          result.add({
            'profile': profile,
            'kyc_documents': docs.first,
            'kyc_personal': personal.first,
          });
        }
      }

      return result;
    } catch (e) {
      debugPrint('Error fetching pending KYC: $e');
      rethrow;
    }
  }

  /// Fetch animals for a shelter user from animals_for_adoption table
  Future<List<Map<String, dynamic>>> _fetchShelterPets(String userId) async {
    try {
      final animals = await Supabase.instance.client
          .from('animals_for_adoption')
          .select('*')
          .eq('shelter_id', userId)
          .order('created_at', ascending: false);
      return animals;
    } catch (e) {
      debugPrint('Error fetching shelter animals: $e');
      return [];
    }
  }

  /// Approve KYC and set kyc_verified to true
  Future<void> _approveKyc(String userId) async {
    try {
      // Call the database function to approve the KYC
      await Supabase.instance.client.rpc('approve_kyc', params: {'target_user_id': userId});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KYC approved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the pending KYC list
        setState(() {
          _pendingKycFuture = _fetchPendingKyc();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving KYC: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error in _approveKyc: $e');
    }
  }

  /// Reject/delete KYC request
  Future<void> _rejectKyc(String userId) async {
    try {
      // Delete KYC documents and personal records
      await Supabase.instance.client
          .from('kyc_documents')
          .delete()
          .eq('user_id', userId);

      await Supabase.instance.client
          .from('kyc_personal')
          .delete()
          .eq('user_id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KYC request rejected.'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _pendingKycFuture = _fetchPendingKyc();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting KYC: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showKycDetails(Map<String, dynamic> kycData) {
    final userId = kycData['profile']['user_id'];
    
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
                Text(
                  'KYC Details & Verification',
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                
                // Profile Info
                _buildDetailSection('Profile Information', {
                  'Shelter Name': kycData['profile']['first_name'] ?? 'N/A',
                  'Email': kycData['profile']['email'] ?? 'N/A',
                  'Phone': kycData['profile']['phone'] ?? 'N/A',
                  'City': kycData['profile']['city'] ?? 'N/A',
                  'State': kycData['profile']['state'] ?? 'N/A',
                  'Country': kycData['profile']['country'] ?? 'N/A',
                }),
                const SizedBox(height: 16),

                // KYC Personal Verification
                if (kycData['kyc_personal'] != null)
                  _buildKycPersonalSection(kycData['kyc_personal']),
                const SizedBox(height: 16),

                // KYC Documents with Images (use exact field names from KYC form)
                if (kycData['kyc_documents'] != null)
                  _buildKycDocumentsSection(kycData['kyc_documents']),
                const SizedBox(height: 16),

                // Shelter Pets List
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchShelterPets(userId),
                  builder: (ctx, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return _buildPetsSection(snapshot.data!);
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 24),

                // Action buttons - Fixed layout
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Flexible(
                        child: ElevatedButton(
                          onPressed: () {
                            _approveKyc(kycData['profile']['user_id']);
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: const Text('Approve', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: ElevatedButton(
                          onPressed: () {
                            _rejectKyc(kycData['profile']['user_id']);
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: const Text('Reject', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKycPersonalSection(Map<String, dynamic> personal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Verification',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        _buildVerificationRow('Full Name', personal['full_name'] ?? 'N/A'),
        _buildVerificationRow('Phone', personal['phone'] ?? 'N/A'),
        _buildVerificationRow('OTP Verified', (personal['is_otp_verified'] == true) ? '✓ Yes' : '✗ No'),
        _buildVerificationRow('Status', personal['status'] ?? 'Pending'),
      ],
    );
  }

  Widget _buildKycDocumentsSection(Map<String, dynamic> docs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KYC Documents',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        _buildVerificationRow('Document Status', docs['status'] ?? 'Pending'),
        _buildVerificationRow('Submitted Date', docs['created_at'] ?? 'N/A'),
        _buildVerificationRow('Aadhaar Number', docs['aadhaar_number'] ?? 'N/A'),
        const SizedBox(height: 12),

        // Aadhaar Image
        if (docs['aadhaar_image_url'] != null) ...[
          Text('Aadhaar Image:', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _showImagePreview(docs['aadhaar_image_url'], 'Aadhaar Image'),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  docs['aadhaar_image_url'],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(child: Text('Image unavailable')),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Selfie Photo
        if (docs['selfie_image_url'] != null) ...[
          Text('Selfie Photo:', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _showImagePreview(docs['selfie_image_url'], 'Selfie'),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  docs['selfie_image_url'],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(child: Text('Image unavailable')),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPetsSection(List<Map<String, dynamic>> pets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shelter Pets (${pets.length})',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet['name'] ?? 'Unknown Pet',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${pet['species'] ?? 'N/A'} • ${pet['breed'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildVerificationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePreview(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title),
              automaticallyImplyLeading: true,
            ),
            Expanded(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(child: Text('Image unavailable')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, Map<String, String> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        ...details.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.key, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Flexible(
                  child: Text(
                    e.value,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('KYC Approvals', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 1,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _pendingKycFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No pending KYC requests.'));
          }

          final kycRequests = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: kycRequests.length,
            itemBuilder: (context, index) {
              final kycData = kycRequests[index];
              final profile = kycData['profile'] as Map<String, dynamic>;
              final shelterName = profile['first_name'] ?? 'Unknown';
              final phone = profile['phone'] ?? 'N/A';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.verified_user_outlined, color: Colors.orange),
                  title: Text(shelterName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(phone),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showKycDetails(kycData),
                ),
              );
            },
          );
        },
      ),
    );
  }
}