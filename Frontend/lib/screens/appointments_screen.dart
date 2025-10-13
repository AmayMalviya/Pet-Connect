import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppointmentsScreen extends StatefulWidget {
  static const routeName = '/appointments';

  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _appointments = [];

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    // TODO: Implement Supabase
    // setState(() {
    //   _isLoading = true;
    // });
    // try {
    //   final user = FirebaseAuth.instance.currentUser;
    //   if (user != null) {
    //     final snapshot = await FirebaseFirestore.instance
    //         .collection('appointments')
    //         .where('vetId', isEqualTo: user.uid)
    //         .get();

    //     final List<Map<String, dynamic>> loadedAppointments = [];
    //     for (var doc in snapshot.docs) {
    //       final appointmentData = doc.data();
    //       final patientDoc = await FirebaseFirestore.instance.collection('users').doc(appointmentData['ownerId']).collection('pets').doc(appointmentData['petId']).get();
    //       final ownerDoc = await FirebaseFirestore.instance.collection('users').doc(appointmentData['ownerId']).get();

    //       if (patientDoc.exists && ownerDoc.exists) {
    //         loadedAppointments.add({
    //           'id': doc.id,
    //           'petName': patientDoc.data()!['name'],
    //           'ownerName': ownerDoc.data()!['name'],
    //           'time': (appointmentData['time'] as Timestamp).toDate().toString(), // Example: Convert timestamp to string
    //           'status': appointmentData['status'],
    //         });
    //       }
    //     }
    //     setState(() {
    //       _appointments = loadedAppointments;
    //     });
    //   }
    // } catch (e) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Failed to load appointments: $e')),
    //   );
    // } finally {
    //   setState(() {
    //     _isLoading = false;
    //   });
    // }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateAppointmentStatus(String appointmentId, String status) async {
    // TODO: Implement Supabase
    // try {
    //   await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update({'status': status});
    //   _fetchAppointments(); // Refresh the list
    // } catch (e) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Failed to update status: $e')),
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Appointments', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        leading: const BackButton(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _appointments.length,
              itemBuilder: (context, index) {
                final appointment = _appointments[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.pets),
                    ),
                    title: Text(
                      '${appointment['petName']} with ${appointment['ownerName']}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Appointment at ${appointment['time']} - Status: ${appointment['status']}',
                      style: GoogleFonts.poppins(),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (appointment['status'] == 'Pending') ...[
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () => _updateAppointmentStatus(appointment['id'], 'Confirmed'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => _updateAppointmentStatus(appointment['id'], 'Cancelled'),
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}