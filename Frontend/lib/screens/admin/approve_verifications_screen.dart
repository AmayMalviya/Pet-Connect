import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApproveVerificationsScreen extends StatefulWidget {
  static const routeName = '/approve-verifications';

  const ApproveVerificationsScreen({super.key});

  @override
  State<ApproveVerificationsScreen> createState() => _ApproveVerificationsScreenState();
}

class _ApproveVerificationsScreenState extends State<ApproveVerificationsScreen> {
  late Future<List<Map<String, dynamic>>> _pendingVerificationsFuture;

  @override
  void initState() {
    super.initState();
    _pendingVerificationsFuture = _fetchPendingVerifications();
  }

  Future<List<Map<String, dynamic>>> _fetchPendingVerifications() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('profiles')
        .select('*')
        // Accept both legacy 'Shelter Owner' and canonical 'Shelter'
        .or('role.eq.Shelter,role.eq.Shelter Owner')
        .eq('kyc_verified', false);
    return response;
  }

  Future<void> _approveVerification(String userId) async {
    final supabase = Supabase.instance.client;
    await supabase
        .from('profiles')
        .update({'kyc_verified': true})
        .eq('user_id', userId);
    setState(() {
      _pendingVerificationsFuture = _fetchPendingVerifications(); // Refresh the list
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shelter approved successfully!')),
    );
  }

  Future<void> _rejectVerification(String userId) async {
    // For now, we'll just remove it from the list. In a real app, you might update a 'kyc_status' to 'rejected'
    // or delete the profile if it's a fraudulent submission.
    // For this implementation, we'll just refresh the list to make it disappear.
    setState(() {
      _pendingVerificationsFuture = _fetchPendingVerifications(); // Refresh the list
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shelter verification rejected.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approve Verifications'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _pendingVerificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No pending verifications.'));
          }

          final pendingVerifications = snapshot.data!;

          return ListView.builder(
            itemCount: pendingVerifications.length,
            itemBuilder: (context, index) {
              final profile = pendingVerifications[index];
              final shelterName = profile['shelter_name'] ?? 'N/A';
              final userId = profile['user_id'] as String;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shelterName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('User ID: $userId'),
                      // Add more details if needed, e.g., contact info, submitted documents
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () => _approveVerification(userId),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text('Approve', style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () => _rejectVerification(userId),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Reject', style: TextStyle(color: Colors.white)),
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
}
