import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScanPetQrScreen extends StatelessWidget {
  static const routeName = '/scan-pet-qr';

  const ScanPetQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Pet QR', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        leading: const BackButton(),
  backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.qr_code_scanner,
                  size: 100,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Position the QR code inside the frame',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement QR code scanning functionality
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan QR Code'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: GoogleFonts.poppins(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}