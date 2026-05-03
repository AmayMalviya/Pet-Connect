import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/screens/chat_screen.dart';
import 'package:pet_connect_app/theme/app_theme.dart'; // Ensure you have this or replace AppColors.primary with Theme.of(context).primaryColor

class MyAdoptionRequestsScreen extends StatefulWidget {
  static const routeName = '/my-adoption-requests';

  const MyAdoptionRequestsScreen({Key? key}) : super(key: key);

  @override
  State<MyAdoptionRequestsScreen> createState() => _MyAdoptionRequestsScreenState();
}

class _MyAdoptionRequestsScreenState extends State<MyAdoptionRequestsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchMyRequests();
  }

  Future<void> _fetchMyRequests() async {
    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('adoption_requests')
          .select('id, status, shelter_owner_id, pets(name)')
          .eq('requester_id', user.id)
          .order('id', ascending: false);

      // Fetch shelter profiles separately to prevent Supabase Foreign Key connection errors
      final List<dynamic> shelterIds = response
          .map((r) => r['shelter_owner_id'])
          .where((id) => id != null)
          .toSet()
          .toList();

      Map<String, dynamic> profilesMap = {};
      if (shelterIds.isNotEmpty) {
        final profilesResponse = await Supabase.instance.client
            .from('profiles')
            .select('user_id, first_name, last_name, email')
            .inFilter('user_id', shelterIds);
        for (var p in profilesResponse) {
          profilesMap[p['user_id']] = p;
        }
      }

      final formattedRequests = response.map((req) {
        return {
          ...req,
          'profiles': profilesMap[req['shelter_owner_id']] ?? {},
        };
      }).toList();

      setState(() {
        _requests = formattedRequests;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching my adoption requests: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Adoption Requests',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? Center(
                  child: Text(
                    'You haven\'t made any adoption requests yet.',
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchMyRequests,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final req = _requests[index];
                      final pet = (req['pets'] as Map<String, dynamic>?) ?? {};
                      final shelter = (req['profiles'] as Map<String, dynamic>?) ?? {};
                      final status = req['status'] as String? ?? 'Pending';
                      
                      final shelterName = '${shelter['first_name'] ?? ''} ${shelter['last_name'] ?? ''}'.trim();
                      final displayName = shelterName.isNotEmpty ? shelterName : 'Shelter';

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: status == 'Approved' 
                                ? Colors.green.withOpacity(0.2) 
                                : status == 'Rejected' 
                                    ? Colors.red.withOpacity(0.2) 
                                    : Colors.orange.withOpacity(0.2),
                            child: Icon(
                              status == 'Approved' ? Icons.check_circle : status == 'Rejected' ? Icons.cancel : Icons.hourglass_empty,
                              color: status == 'Approved' ? Colors.green : status == 'Rejected' ? Colors.red : Colors.orange,
                            ),
                          ),
                          title: Text(
                            'Request for ${pet['name'] ?? 'Unknown Pet'}',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            'Shelter: $displayName\nStatus: $status',
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                          ),
                          trailing: status == 'Approved'
                              ? IconButton(
                                  icon: const Icon(Icons.chat_bubble, color: Colors.blueAccent, size: 28),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(
                                          requestId: req['id'].toString(),
                                          otherUserName: displayName,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}