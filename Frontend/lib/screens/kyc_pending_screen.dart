import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_connect_app/screens/shelter_home_screen.dart';

class KycPendingScreen extends StatefulWidget {
  static const routeName = '/kyc-pending';

  const KycPendingScreen({super.key});

  @override
  State<KycPendingScreen> createState() => _KycPendingScreenState();
}

class _KycPendingScreenState extends State<KycPendingScreen> {
  late final Stream<Map<String, dynamic>?> _kycStream;

  @override
  void initState() {
    super.initState();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _kycStream = Stream.value(null);
      return;
    }
    _kycStream = Supabase.instance.client
        .from('profiles')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((data) => data.isNotEmpty ? data.first : null)
        .asBroadcastStream(); // Use asBroadcastStream to allow for navigation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Pending'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _kycStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data != null) {
            final isVerified = snapshot.data!['kyc_verified'] == true;
            if (isVerified) {
              // Use a post-frame callback to safely navigate after the build phase
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.pushReplacementNamed(context, ShelterHomeScreen.routeName);
                }
              });
              // Show a loading indicator while navigating
              return const Center(child: CircularProgressIndicator());
            }
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.hourglass_top, size: 80, color: Colors.orange),
                const SizedBox(height: 20),
                const Text(
                  'Your verification is pending review',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                const Text(
                  'We have received your documents and personal verification details. An admin will review them shortly. You will be notified when verification completes.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/kyc-document');
                  },
                  child: const Text('Edit / Re-submit documents'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
