import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:pet_connect_app/models/user.dart' as pet_connect_user;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/models/adoption_request.dart';

class AdoptionRequestsScreen extends StatefulWidget {
  static const routeName = '/adoption-requests';

  const AdoptionRequestsScreen({super.key});

  @override
  State<AdoptionRequestsScreen> createState() => _AdoptionRequestsScreenState();
}

class _AdoptionRequestsScreenState extends State<AdoptionRequestsScreen> {
  bool _isLoading = true;
  List<AdoptionRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchAdoptionRequests();
  }

  Future<void> _fetchAdoptionRequests() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('adoption_requests')
            .select('*, pets(*), profiles(*)')
            .eq('shelter_owner_id', user.id);

        final List<AdoptionRequest> loadedRequests = [];
        for (var req in response as List) {
          final petData = req['pets'];
          final requesterData = req['profiles'];

          if (petData != null && requesterData != null) {
            loadedRequests.add(AdoptionRequest(
              id: req['id'],
              petId: req['pet_id'],
              requesterId: req['requester_id'],
              shelterOwnerId: req['shelter_owner_id'],
              status: req['status'],
              pet: Pet.fromJson(petData),
              requester: pet_connect_user.User.fromJson(requesterData),
            ));
          }
        }
        setState(() {
          _requests = loadedRequests;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load adoption requests: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateRequestStatus(int requestId, String status) async {
    try {
      await Supabase.instance.client
          .from('adoption_requests')
          .update({'status': status})
          .eq('id', requestId);
      _fetchAdoptionRequests(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adoption Requests', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        leading: const BackButton(),
  backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final request = _requests[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.person),
                    ),
                    title: Text(
                      '${request.requester.displayName} for ${request.pet.name}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Status: ${request.status}',
                      style: GoogleFonts.poppins(),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () => _updateRequestStatus(request.id, 'Approved'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => _updateRequestStatus(request.id, 'Rejected'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
