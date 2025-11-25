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
  bool _loading = false;
  bool _refreshing = false;

  Future<void> _refreshStatus() async {
    setState(() => _refreshing = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('kyc_verified')
          .eq('user_id', user.id)
          .maybeSingle();

      final verified = profile != null && profile['kyc_verified'] == true;
      if (verified) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, ShelterHomeScreen.routeName);
      }
    } catch (e) {
      // ignore - we'll show message
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
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
      body: Padding(
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
            ElevatedButton.icon(
              onPressed: _refreshing ? null : _refreshStatus,
              icon: _refreshing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.refresh),
              label: Text(_refreshing ? 'Checking...' : 'Check Status'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                // allow user to re-open the document KYC screen if they want to re-submit
                Navigator.pushNamed(context, '/kyc-document');
              },
              child: const Text('Edit / Re-submit documents'),
            ),
          ],
        ),
      ),
    );
  }
}
