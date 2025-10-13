import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:pet_connect_app/screens/patient_details_screen.dart';

class MyPatientsScreen extends StatefulWidget {
  static const routeName = '/my-patients';

  const MyPatientsScreen({super.key});

  @override
  State<MyPatientsScreen> createState() => _MyPatientsScreenState();
}

class _MyPatientsScreenState extends State<MyPatientsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _patients = [];

  @override
  void initState() {
    super.initState();
    _fetchMyPatients();
  }

  Future<void> _fetchMyPatients() async {
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

    //     final Map<String, Map<String, dynamic>> uniquePatients = {};

    //     for (var doc in snapshot.docs) {
    //       final appointmentData = doc.data();
    //       final petId = appointmentData['petId'];

    //       if (!uniquePatients.containsKey(petId)) {
    //         final ownerId = appointmentData['ownerId'];
    //         final petDoc = await FirebaseFirestore.instance.collection('users').doc(ownerId).collection('pets').doc(petId).get();
    //         final ownerDoc = await FirebaseFirestore.instance.collection('users').doc(ownerId).get();

    //         if (petDoc.exists && ownerDoc.exists) {
    //           uniquePatients[petId] = {
    //             'id': petId,
    //             'name': petDoc.data()!['name'],
    //             'breed': petDoc.data()!['breed'],
    //             'ownerName': ownerDoc.data()!['name'],
    //           };
    //         }
    //       }
    //     }
    //     setState(() {
    //       _patients = uniquePatients.values.toList();
    //     });
    //   }
    // } catch (e) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Failed to load patients: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Patients', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        leading: const BackButton(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _patients.length,
              itemBuilder: (context, index) {
                final patient = _patients[index];
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
                      patient['name']!,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${patient['breed']} - Owner: ${patient['ownerName']}',
                      style: GoogleFonts.poppins(),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PatientDetailsScreen(patientData: patient),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}