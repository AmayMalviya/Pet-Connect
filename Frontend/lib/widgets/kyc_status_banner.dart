import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/kyc_document_screen.dart';

class KycStatusBanner extends StatelessWidget {
  const KycStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('profiles')
          .stream(primaryKey: ['user_id'])
          .eq('user_id', userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final profile = snapshot.data!.first;
        final kycVerified = profile['kyc_verified'] == true;
        final kycStatus = profile['kyc_status'] as String? ?? 'unverified';

        if (kycVerified) return const SizedBox.shrink();

        Color bannerColor;
        String message;
        IconData icon;
        VoidCallback? onTap;

        if (kycStatus == 'rejected') {
          bannerColor = Colors.redAccent;
          message = "Your KYC was rejected. Tap to resubmit.";
          icon = Icons.error_outline;
          onTap = () {
            Navigator.pushNamed(context, KycDocumentScreen.routeName);
          };
        } else if (kycStatus == 'pending') {
          bannerColor = Colors.orangeAccent;
          message = "Your account is pending verification. Some features are limited.";
          icon = Icons.hourglass_empty;
        } else {
          bannerColor = Colors.blueAccent;
          message = "Complete your KYC to unlock all features.";
          icon = Icons.info_outline;
          onTap = () {
            Navigator.pushNamed(context, KycDocumentScreen.routeName);
          };
        }

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bannerColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (onTap != null)
                  const Icon(Icons.chevron_right, color: Colors.white, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
