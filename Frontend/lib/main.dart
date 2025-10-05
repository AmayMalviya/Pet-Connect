import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pet_connect_app/screens/add_pet_screen.dart';
import 'package:pet_connect_app/screens/main_screen.dart';
import 'package:pet_connect_app/theme/app_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pet_connect_app/screens/self_care_options_screen.dart';
import 'package:pet_connect_app/screens/health_details_screen.dart';
import 'package:pet_connect_app/screens/services_screen.dart';
import 'package:pet_connect_app/screens/shop_screen.dart';
import 'package:pet_connect_app/screens/grooming_details_screen.dart';
import 'package:pet_connect_app/screens/training_details_screen.dart';
import 'package:pet_connect_app/screens/vet_details_screen.dart';
import 'package:pet_connect_app/screens/nutrition_advice_screen.dart';
import 'package:pet_connect_app/screens/role_selection_screen.dart';
import 'package:pet_connect_app/screens/kyc_screen.dart';
import 'package:pet_connect_app/screens/vet_home_screen.dart';
import 'package:pet_connect_app/screens/shelter_home_screen.dart';
import 'package:pet_connect_app/screens/appointments_screen.dart';
import 'package:pet_connect_app/screens/my_patients_screen.dart';
import 'package:pet_connect_app/screens/scan_pet_qr_screen.dart';
import 'package:pet_connect_app/screens/vet_profile_screen.dart';
import 'package:pet_connect_app/screens/shelter/shelter_pets_screen.dart';
import 'package:pet_connect_app/screens/shelter/adoption_requests_screen.dart';
import 'package:pet_connect_app/screens/shelter/shelter_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const PetConnectApp());
}

class PetConnectApp extends StatelessWidget {
  const PetConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Connect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (snapshot.hasData) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final userRole = userSnapshot.data!.get('role');
                  if (userRole == 'Pet Owner') {
                    return const MainScreen();
                  } else if (userRole == 'Vet') {
                    return const VetHomeScreen();
                  } else if (userRole == 'Shelter Owner') {
                    return const ShelterHomeScreen();
                  }
                }
                return const RoleSelectionScreen();
              },
            );
          } else {
            return const AuthScreen();
          }
        },
      ),
      routes: {
        AuthScreen.routeName: (context) => const AuthScreen(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        RegisterScreen.routeName: (context) => const RegisterScreen(),
        ProfileScreen.routeName: (context) => const ProfileScreen(),
        MainScreen.routeName: (context) => const MainScreen(),
        AddPetScreen.routeName: (context) => const AddPetScreen(),
        SelfCareOptionsScreen.routeName: (context) => const SelfCareOptionsScreen(),
        HealthDetailsScreen.routeName: (context) => const HealthDetailsScreen(),
        ServicesScreen.routeName: (context) => const ServicesScreen(),
        ShopScreen.routeName: (context) => const ShopScreen(),
        GroomingDetailsScreen.routeName: (context) => const GroomingDetailsScreen(),
        TrainingDetailsScreen.routeName: (context) => const TrainingDetailsScreen(),
        VetDetailsScreen.routeName: (context) => const VetDetailsScreen(),
        NutritionAdviceScreen.routeName: (context) => const NutritionAdviceScreen(),
        RoleSelectionScreen.routeName: (context) => const RoleSelectionScreen(),
        KycScreen.routeName: (context) => const KycScreen(),
        VetHomeScreen.routeName: (context) => const VetHomeScreen(),
        ShelterHomeScreen.routeName: (context) => const ShelterHomeScreen(),
        AppointmentsScreen.routeName: (context) => const AppointmentsScreen(),
        MyPatientsScreen.routeName: (context) => const MyPatientsScreen(),
        ScanPetQrScreen.routeName: (context) => const ScanPetQrScreen(),
        VetProfileScreen.routeName: (context) => const VetProfileScreen(),
        ShelterPetsScreen.routeName: (context) => const ShelterPetsScreen(),
        AdoptionRequestsScreen.routeName: (context) => const AdoptionRequestsScreen(),
        ShelterProfileScreen.routeName: (context) => const ShelterProfileScreen(),
      },
    );
  }
}