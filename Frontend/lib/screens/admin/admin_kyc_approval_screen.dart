import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:functions_client/functions_client.dart';
import 'package:pet_connect_app/models/user.dart';

class AdminKycApprovalScreen extends StatefulWidget {
  static const routeName = '/admin-kyc-approval';

  const AdminKycApprovalScreen({super.key});

  @override
  _AdminKycApprovalScreenState createState() => _AdminKycApprovalScreenState();
}

class _AdminKycApprovalScreenState extends State<AdminKycApprovalScreen> {
  late Future<List<User>> _kycProfilesFuture;

  @override
  void initState() {
    super.initState();
    _kycProfilesFuture = _fetchKycProfiles();
  }

  Future<List<User>> _fetchKycProfiles() async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('role', 'Shelter')
          .eq('kyc_verified', false);

      final data = response as List<dynamic>;
      return data.map((json) => User.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching KYC profiles: $e');
      rethrow;
    }
  }

  Future<void> _approveKyc(String userId, String? idPhotoPath, String? selfiePath) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'verify-identity',
        body: {
          'userId': userId,
          'idPhotoPath': idPhotoPath,
          'selfiePath': selfiePath,
        },
      );

      if (response.status != 200) {
        debugPrint("⚠️ FCM error: ${response.data}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving KYC: ${response.data}'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KYC approved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _kycProfilesFuture = _fetchKycProfiles();
        });
      }
    } catch (e) {
      debugPrint("⚠️ Error calling function: ${e.runtimeType} - $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.runtimeType} - $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Approval'),
      ),
      body: FutureBuilder<List<User>>(
        future: _kycProfilesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No pending KYC requests.'));
          }

          final profiles = snapshot.data!;
          return ListView.builder(
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              return Card(
                key: ValueKey(profile.uid),
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(profile.displayName),
                  subtitle: Text(profile.email),
                  trailing: SizedBox(
                    width: 80.0, // Adjust width as needed
                    child: ElevatedButton(
                      onPressed: () => _approveKyc(profile.uid, profile.idPhotoPath, profile.selfiePath),
                      child: const Text('Approve'),
                    ),
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