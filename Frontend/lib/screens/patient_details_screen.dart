
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PatientDetailsScreen extends StatelessWidget {
  static const routeName = '/patient-details';
  final Map<String, dynamic> patientData;

  const PatientDetailsScreen({super.key, required this.patientData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(patientData['name'] ?? 'Patient Details', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              patientData['name'] ?? 'No Name',
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Breed: ${patientData['breed'] ?? 'Unknown'}',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Owner: ${patientData['ownerName'] ?? 'Unknown'}',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            const SizedBox(height: 30),
            Text(
              'Medical History',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(thickness: 1),
            const SizedBox(height: 10),
            // Placeholder for medical history
            const Center(
              child: Text('No medical history available.'),
            ),
          ],
        ),
      ),
    );
  }
}
