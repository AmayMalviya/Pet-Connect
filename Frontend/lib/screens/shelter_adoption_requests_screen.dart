import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/theme/app_theme.dart';

class ShelterAdoptionRequestsScreen extends StatefulWidget {
  static const routeName = '/shelter-adoption-requests';
  const ShelterAdoptionRequestsScreen({Key? key}) : super(key: key);

  @override
  State<ShelterAdoptionRequestsScreen> createState() => _ShelterAdoptionRequestsScreenState();
}

class _ShelterAdoptionRequestsScreenState extends State<ShelterAdoptionRequestsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchAdoptionRequests();
  }

  Future<void> _fetchAdoptionRequests() async {
    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // Query using `shelter_owner_id` (the column name used when inserting adoption requests)
      final response = await Supabase.instance.client
          .from('adoption_requests')
          .select('id, pet_id, status, created_at, pets(name, animal, breed), profiles!requester_id(first_name, last_name, email, phone, city, state)')
          .eq('shelter_owner_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _requests = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching adoption requests: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateRequestStatus(String requestId, String status) async {
    try {
      // Fetch requester FCM token to notify them
      final request = await Supabase.instance.client
          .from('adoption_requests')
          .select('requester_id, pets(name)')
          .eq('id', requestId)
          .maybeSingle();

      await Supabase.instance.client
          .from('adoption_requests')
          .update({'status': status})
          .eq('id', requestId);

      if (request != null) {
        try {
          final requesterProfile = await Supabase.instance.client
              .from('profiles')
              .select('fcm_token')
              .eq('user_id', request['requester_id'])
              .maybeSingle();

          if (requesterProfile?['fcm_token'] != null) {
            final petName = request['pets'] != null ? request['pets']['name'] ?? 'your pet' : 'your pet';
            await Supabase.instance.client.functions.invoke(
              'send_fcm',
              body: {
                'token': requesterProfile?['fcm_token'],
                'title': 'Adoption ${status == 'Approved' ? 'Approved 🎉' : 'Rejected ❌'}',
                'body': 'Your adoption request for $petName was $status.',
              },
            );
          }
        } catch (fcmErr) {
          debugPrint('FCM error (non-fatal): $fcmErr');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request $status successfully!')),
        );
        _fetchAdoptionRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating request: $e')),
        );
      }
    }
  }

  void _showOwnerDetails(Map<String, dynamic> requester) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Interested Owner',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(Icons.person, '${requester['first_name'] ?? ''} ${requester['last_name'] ?? ''}'.trim()),
            const SizedBox(height: 8),
            _detailRow(Icons.email_outlined, requester['email'] ?? 'N/A'),
            const SizedBox(height: 8),
            if ((requester['phone'] as String?) != null && (requester['phone'] as String).isNotEmpty)
              _detailRow(Icons.phone_outlined, requester['phone']),
            if ((requester['city'] as String?) != null && (requester['city'] as String).isNotEmpty) ...[
              const SizedBox(height: 8),
              _detailRow(
                Icons.location_on_outlined,
                [requester['city'], requester['state']].where((s) => s != null && (s as String).isNotEmpty).join(', '),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 14))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Adoption Requests',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? Center(child: Text('No adoption requests yet.', style: GoogleFonts.poppins()))
              : RefreshIndicator(
                  onRefresh: _fetchAdoptionRequests,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final req = _requests[index];
                      final requester = (req['profiles'] as Map<String, dynamic>?) ?? {};
                      final pet = (req['pets'] as Map<String, dynamic>?) ?? {};
                      final status = req['status'] as String? ?? 'Pending';
                      final requesterName = '${requester['first_name'] ?? ''} ${requester['last_name'] ?? ''}'.trim();

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '🐾 ${pet['name'] ?? 'Unknown Pet'}',
                                          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold),
                                        ),
                                        if ((pet['breed'] as String?) != null)
                                          Text(
                                            '${pet['animal'] ?? ''} • ${pet['breed']}',
                                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      status,
                                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                                    ),
                                    backgroundColor: status == 'Approved'
                                        ? Colors.green
                                        : status == 'Rejected'
                                            ? Colors.red
                                            : Colors.orange,
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              // Requester info row
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.primary.withOpacity(0.15),
                                    child: Text(
                                      requesterName.isNotEmpty ? requesterName[0].toUpperCase() : '?',
                                      style: GoogleFonts.poppins(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          requesterName.isNotEmpty ? requesterName : 'Unknown',
                                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                        ),
                                        if ((requester['city'] as String?) != null)
                                          Text(
                                            '📍 ${[requester['city'], requester['state']].where((s) => s != null && (s as String).isNotEmpty).join(', ')}',
                                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                                          ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _showOwnerDetails(requester),
                                    child: Text(
                                      'View Details',
                                      style: GoogleFonts.poppins(color: AppColors.primary, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const SizedBox(height: 8),
                              Text(
                                '🕒 ${DateTime.parse(req['created_at']).toLocal().toString().substring(0, 16)}',
                                style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
                              ),
                              if (status == 'Pending') ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.check, size: 16),
                                        label: Text('Approve', style: GoogleFonts.poppins()),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          minimumSize: const Size(0, 42),
                                        ),
                                        onPressed: () => _updateRequestStatus(req['id'].toString(), 'Approved'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.close, size: 16),
                                        label: Text('Reject', style: GoogleFonts.poppins()),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          minimumSize: const Size(0, 42),
                                        ),
                                        onPressed: () => _updateRequestStatus(req['id'].toString(), 'Rejected'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
