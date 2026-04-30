import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/theme/app_theme.dart';

import 'package:pet_connect_app/services/storage_service.dart';

class AdminKycApprovalScreen extends StatefulWidget {
  static const routeName = '/admin-kyc-approval';

  const AdminKycApprovalScreen({super.key});

  @override
  State<AdminKycApprovalScreen> createState() => _AdminKycApprovalScreenState();
}

class _AdminKycApprovalScreenState extends State<AdminKycApprovalScreen> {
  late Future<List<Map<String, dynamic>>> _pendingKycFuture;
  final _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _pendingKycFuture = _fetchPendingKyc();
  }

  Future<List<Map<String, dynamic>>> _fetchPendingKyc() async {
    try {
      // Fetch all shelters that are NOT verified
      final profilesResponse = await Supabase.instance.client
          .from('profiles')
          .select('*, shelter_kyc:shelter_kyc!shelter_kyc_user_id_fkey(*)')
          .inFilter('role', ['Shelter', 'Shelter Owner'])
          .neq('kyc_verified', true)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> results = [];
      
      for (var p in profilesResponse) {
        final Map<String, dynamic> profile = Map<String, dynamic>.from(p as Map);
        final kycList = profile['shelter_kyc'] as List<dynamic>?;
        
        if (kycList != null && kycList.isNotEmpty) {
          // Prioritize pending submissions
          Map<String, dynamic>? targetKyc;
          try {
            targetKyc = kycList.firstWhere(
              (k) => k['status'] == 'pending' || k['status'] == 'pending_review'
            );
          } catch (_) {
            targetKyc = kycList.first;
          }
          
          results.add({
            ...Map<String, dynamic>.from(targetKyc!),
            'profiles': profile,
          });
        } else {
          // Mock a KYC request object for those who haven't submitted
          results.add({
            'user_id': profile['user_id'],
            'id': -1, // Mock ID
            'first_name': profile['first_name'],
            'last_name': profile['last_name'],
            'phone': profile['phone'],
            'aadhaar_number': null,
            'status': 'not_submitted',
            'created_at': profile['created_at'],
            'profiles': profile,
          });
        }
      }

      return results;
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

  /// Approve KYC
  Future<void> _approveSubmission(String userId, int submissionId) async {
    final adminId = Supabase.instance.client.auth.currentUser!.id;
    try {
      // 1. Update shelter_kyc if it exists
      if (submissionId != -1) {
        await Supabase.instance.client.from('shelter_kyc').update({
          'status': 'approved',
          'reviewed_by': adminId,
          'reviewed_at': DateTime.now().toIso8601String(),
        }).eq('id', submissionId);
      }

      // 2. Update profiles
      await Supabase.instance.client.from('profiles').update({
        'kyc_status': 'completed',
        'kyc_verified': true,
        'kyc_submitted': true,
      }).eq('user_id', userId);

      // 3. Send notification
      await Supabase.instance.client.from('notifications').insert({
        'recipient_id': userId,
        'title': 'KYC Update',
        'body': 'Your KYC has been approved.',
        'type': 'kyc_update',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KYC approved successfully!'), backgroundColor: Colors.green),
        );
        setState(() => _pendingKycFuture = _fetchPendingKyc());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// Reject KYC
  Future<void> _rejectSubmission(String userId, int submissionId) async {
    final controller = TextEditingController();
    final adminId = Supabase.instance.client.auth.currentUser!.id;

    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject KYC'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Reason for rejection'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Reject')),
        ],
      ),
    );

    if (note == null || note.isEmpty) return;

    try {
      // 1. Update shelter_kyc
      await Supabase.instance.client.from('shelter_kyc').update({
        'status': 'rejected',
        'reviewer_note': note,
        'reviewed_by': adminId,
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', submissionId);

      // 2. Update profiles
      await Supabase.instance.client.from('profiles').update({
        'kyc_status': 'rejected',
      }).eq('user_id', userId);

      // 3. Send notification
      await Supabase.instance.client.from('notifications').insert({
        'recipient_id': userId,
        'title': 'KYC Update',
        'body': 'Your KYC was rejected: $note',
        'type': 'kyc_update',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KYC rejected.'), backgroundColor: Colors.orange),
        );
        setState(() => _pendingKycFuture = _fetchPendingKyc());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
                        child: Text(
                          'Actions disabled in this view',
                          style: TextStyle(color: Colors.grey),
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
          FutureBuilder<String?>(
            future: _storage.getKycSignedUrl(docs['aadhaar_image_url']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(height: 120, width: double.infinity, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator()));
              }
              final signedUrl = snapshot.data;
              if (signedUrl == null) return const Text('Image unavailable');
              
              return GestureDetector(
                onTap: () => _showImagePreview(signedUrl, 'Aadhaar Image'),
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
                      signedUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(child: Text('Image unavailable')),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],

        // Selfie Photo
        if (docs['selfie_image_url'] != null) ...[
          Text('Selfie Photo:', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 4),
          FutureBuilder<String?>(
            future: _storage.getKycSignedUrl(docs['selfie_image_url']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(height: 120, width: double.infinity, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator()));
              }
              final signedUrl = snapshot.data;
              if (signedUrl == null) return const Text('Image unavailable');

              return GestureDetector(
                onTap: () => _showImagePreview(signedUrl, 'Selfie'),
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
                      signedUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(child: Text('Image unavailable')),
                    ),
                  ),
                ),
              );
            },
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('KYC Approvals', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
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
            padding: const EdgeInsets.all(16),
            itemCount: kycRequests.length,
            itemBuilder: (context, index) {
              final kyc = kycRequests[index];
              final profile = kyc['profiles'] as Map<String, dynamic>;
              final userId = kyc['user_id'];
              final submissionId = kyc['id'];
              
              // Always read display name from the profiles row, not the KYC record.
              // KYC records may not have first_name for not_submitted users.
              final firstName = (profile['first_name'] as String? ?? '').trim();
              final lastName = (profile['last_name'] as String? ?? '').trim();
              final fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
              final displayName = fullName.isNotEmpty ? fullName : (profile['email'] ?? 'Unknown User');
              final phone = profile['phone'] ?? kyc['phone'] ?? 'N/A';
              final maskedAadhaar = kyc['aadhaar_number'] ?? 'N/A';
              final submittedDate = kyc['created_at'] != null 
                ? DateTime.parse(kyc['created_at']).toLocal().toString().split('.')[0]
                : 'N/A';
              
              final isSignatureValid = kyc['signature_valid'] == true;

              return Card(
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: Colors.black26,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Name and Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  profile['email'] ?? 'No email',
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSignatureValid ? Colors.green[50] : Colors.red[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSignatureValid ? Colors.green : Colors.red),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSignatureValid ? Icons.check_circle : Icons.warning,
                                  size: 14,
                                  color: isSignatureValid ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isSignatureValid ? 'Sig Valid' : 'Sig Invalid',
                                  style: TextStyle(
                                    fontSize: 10, 
                                    fontWeight: FontWeight.bold,
                                    color: isSignatureValid ? Colors.green : Colors.red
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Details Rows
                      _buildInfoRow('Phone', phone),
                      _buildInfoRow('Aadhaar', maskedAadhaar),
                      _buildInfoRow('Submitted', submittedDate),
                      const SizedBox(height: 16),

                      // Offline Verification Data (if available)
                      if (kyc['extracted_name'] != null || kyc['extracted_dob'] != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Offline KYC Extras:",
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                              ),
                              const SizedBox(height: 4),
                              if (kyc['extracted_name'] != null)
                                _buildInfoRow('Verified Name', kyc['extracted_name'], compact: true),
                              if (kyc['extracted_dob'] != null)
                                _buildInfoRow('Verified DOB', kyc['extracted_dob'], compact: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Images Section
                      Text(
                        "Verification Photos:",
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildImageThumbnail(context, kyc['aadhaar_image_url'], 'Aadhaar'),
                            _buildImageThumbnail(context, kyc['selfie_image_url'], 'Selfie'),
                            if (kyc['extracted_photo_url'] != null)
                              _buildImageThumbnail(context, kyc['extracted_photo_url'], 'Offline Photo'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      kyc['status'] == 'not_submitted'
                          ? SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Call a manual verify function logic here, similar to the one in ManageProfiles
                                  _approveSubmission(userId, -1);
                                },
                                icon: const Icon(Icons.verified_user, size: 18),
                                label: const Text('Verify Manually'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _rejectSubmission(userId, submissionId),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text('Reject'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _approveSubmission(userId, submissionId),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      elevation: 0,
                                    ),
                                    child: const Text('Approve'),
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool compact = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(BuildContext context, String? path, String label) {
    if (path == null) return const SizedBox.shrink();
    return FutureBuilder<String?>(
      future: _storage.getKycSignedUrl(path),
      builder: (context, snapshot) {
        return GestureDetector(
          onTap: () {
            if (snapshot.hasData) {
              showDialog(
                context: context,
                builder: (ctx) => Dialog(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Image.network(snapshot.data!),
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
                    ],
                  ),
                ),
              );
            }
          },
          child: Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
              image: snapshot.hasData
                ? DecorationImage(image: NetworkImage(snapshot.data!), fit: BoxFit.cover)
                : null,
            ),
            child: !snapshot.hasData 
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    color: Colors.black54,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                    ),
                  ),
                ),
          ),
        );
      },
    );
  }
}