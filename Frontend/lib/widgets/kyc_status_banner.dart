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

        // Hide banner if verified by boolean flag OR if status indicates verified/completed/approved
        if (kycVerified || kycStatus == 'verified' || kycStatus == 'completed' || kycStatus == 'approved') {
          return const SizedBox.shrink();
        }

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

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [bannerColor, bannerColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: bannerColor,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          minimumSize: const Size(0, 32),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Verify',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
