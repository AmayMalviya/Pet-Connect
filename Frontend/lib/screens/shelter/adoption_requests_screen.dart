import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/theme/app_theme.dart';

class AdoptionRequestsScreen extends StatelessWidget {
  static const routeName = '/shelter-adoption-requests';

  const AdoptionRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adoption Requests', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        leading: const BackButton(), // Added back button
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 1,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0), // Added padding
        itemCount: 5, // Example count
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Adjusted margin
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                child: Icon(Icons.person, color: Theme.of(context).primaryColor),
              ),
              title: Text(
                'Request from Sarah ${index + 1}', // More descriptive user name
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('For Pet: Whiskers ${index + 1} - Status: Pending'), // More descriptive status
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () {
                      // TODO: Approve request
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      // TODO: Reject request
                    },
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
