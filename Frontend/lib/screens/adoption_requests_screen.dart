import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdoptionRequestsScreen extends StatefulWidget {
  static const routeName = '/adoption-requests';

  const AdoptionRequestsScreen({super.key});

  @override
  State<AdoptionRequestsScreen> createState() => _AdoptionRequestsScreenState();
}

class _AdoptionRequestsScreenState extends State<AdoptionRequestsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchAdoptionRequests();
  }

  Future<void> _fetchAdoptionRequests() async {
    // TODO: Implement Supabase
    // setState(() {
    //   _isLoading = true;
    // });
    // try {
    //   final user = FirebaseAuth.instance.currentUser;
    //   if (user != null) {
    //     final snapshot = await FirebaseFirestore.instance
    //         .collection('adoptionRequests')
    //         .where('shelterOwnerId', isEqualTo: user.uid)
    //         .get();

    //     final List<Map<String, dynamic>> loadedRequests = [];
    //     for (var doc in snapshot.docs) {
    //       final requestData = doc.data();
    //       final petDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('pets').doc(requestData['petId']).get();
    //       final requesterDoc = await FirebaseFirestore.instance.collection('users').doc(requestData['requesterId']).get();

    //       if (petDoc.exists && requesterDoc.exists) {
    //         loadedRequests.add({
    //           'id': doc.id,
    //           'petName': petDoc.data()!['name'],
    //           'requesterName': requesterDoc.data()!['name'],
    //           'status': requestData['status'],
    //         });
    //       }
    //     }
    //     setState(() {
    //       _requests = loadedRequests;
    //     });
    //   }
    // } catch (e) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Failed to load adoption requests: $e')),
    //   );
    // } finally {
    //   setState(() {
    //     _isLoading = false;
    //   });
    // }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateRequestStatus(String requestId, String status) async {
    // TODO: Implement Supabase
    // try {
    //   await FirebaseFirestore.instance.collection('adoptionRequests').doc(requestId).update({'status': status});
    //   _fetchAdoptionRequests(); // Refresh the list
    // } catch (e) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Failed to update status: $e')),
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adoption Requests', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        leading: const BackButton(),
        backgroundColor: Colors.white,
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
                      '${request['requesterName']} for ${request['petName']}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Status: ${request['status']}',
                      style: GoogleFonts.poppins(),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () => _updateRequestStatus(request['id'], 'Approved'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => _updateRequestStatus(request['id'], 'Rejected'),
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