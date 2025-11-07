import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      final response = await Supabase.instance.client
          .from('adoption_requests')
          .select('id, pet_id, status, message, created_at, profiles:requester_id(first_name, last_name, email), pets(name)')
          .eq('shelter_owner_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _requests = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching adoption requests: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateRequestStatus(String requestId, String status) async {
    
    final request = await Supabase.instance.client
    .from('adoption_requests')
    .select('requester_id, pets(name)')
    .eq('id', requestId)
    .maybeSingle();

    final requesterProfile = await Supabase.instance.client
    .from('profiles')
    .select('fcm_token')
    .eq('user_id', request?['requester_id'])
    .maybeSingle();

    if (requesterProfile?['fcm_token'] != null) {
    await Supabase.instance.client.functions.invoke(
    'send_fcm',
    body: {
      'token': requesterProfile?['fcm_token'],
      'title': 'Adoption ${status == 'Approved' ? 'Approved 🎉' : 'Rejected ❌'}',
      'body': 'Your adoption request for ${request?['pets']['name']} was $status.',
    },
  );
}

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
                      final requester = req['profiles'] ?? {};
                      final pet = req['pets'] ?? {};
                      final status = req['status'];

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('🐾 ${pet['name'] ?? 'Unknown Pet'}',
                                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text('👤 ${requester['first_name'] ?? ''} ${requester['last_name'] ?? ''}',
                                  style: GoogleFonts.poppins()),
                              Text('📧 ${requester['email'] ?? ''}',
                                  style: GoogleFonts.poppins(color: Colors.grey[700])),
                              const Divider(height: 20),
                              Text('📩 Message: ${req['message'] ?? 'No message'}',
                                  style: GoogleFonts.poppins()),
                              const SizedBox(height: 8),
                              Text('🕒 ${DateTime.parse(req['created_at']).toLocal()}',
                                  style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13)),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Chip(
                                    label: Text(status,
                                        style: GoogleFonts.poppins(color: Colors.white)),
                                    backgroundColor: status == 'Approved'
                                        ? Colors.green
                                        : status == 'Rejected'
                                            ? Colors.red
                                            : Colors.orange,
                                  ),
                                  if (status == 'Pending') ...[
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.check),
                                      label: const Text('Approve'),
                                      onPressed: () => _updateRequestStatus(req['id'], 'Approved'),
                                    ),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.close),
                                      label: const Text('Reject'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      onPressed: () => _updateRequestStatus(req['id'], 'Rejected'),
                                    ),
                                  ]
                                ],
                              ),
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
