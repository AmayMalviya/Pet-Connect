import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RecommendedShopScreen extends StatelessWidget {
  static const routeName = '/recommended-shop';

  const RecommendedShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final petId = args?['petId'] as String?;
    final petName = args?['petName'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Recommended Products for ${petName ?? 'Your Pet'}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'Recommendations coming soon!',
              style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
            ),
            if (petId != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Pet ID: $petId',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
