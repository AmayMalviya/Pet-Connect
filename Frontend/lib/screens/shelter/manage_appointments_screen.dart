import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_connect_app/theme/app_theme.dart';

class ManageAppointmentsScreen extends StatelessWidget {
  static const routeName = '/manage-appointments';

  const ManageAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Appointments', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 1,
      ),
      body: Center(
        child: Text(
          'Appointments Management Coming Soon!',
          style: GoogleFonts.poppins(fontSize: 18),
        ),
      ),
    );
  }
}
