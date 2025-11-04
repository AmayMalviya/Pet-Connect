import 'package:flutter/material.dart';
import 'package:pet_connect_app/firebase_options.dart';
import 'package:pet_connect_app/screens/add_pet_screen.dart';
import 'package:pet_connect_app/screens/main_screen.dart';
import 'package:pet_connect_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
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
import 'package:pet_connect_app/screens/manage_pets_screen.dart';
import 'package:pet_connect_app/screens/adoption_requests_screen.dart';
import 'package:pet_connect_app/screens/shelter_profile_screen.dart';
import 'package:pet_connect_app/screens/edit_profile_screen.dart';
import 'package:pet_connect_app/screens/social_profile_setup_screen.dart';
import 'package:pet_connect_app/screens/map_screen.dart';
import 'package:pet_connect_app/screens/profile_details_screen.dart';
import 'package:pet_connect_app/screens/add_edit_medical_note_screen.dart';
import 'package:pet_connect_app/models/medical_note.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:pet_connect_app/services/notification_service.dart';

final notificationService = NotificationService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await notificationService.init(); // Initialize notification service
  await Supabase.initialize(
    url: 'https://goegjrqmyshnzzonfjav.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdvZWdqcnFteXNobnp6b25mamF2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc0OTMyOTAsImV4cCI6MjA3MzA2OTI5MH0.i4KPxTg_d85Pd8vXMdOYxvoHdrVDZNmGaz30x1ZBglU',
  );
  runApp(const PetConnectApp());
}

class PetConnectApp extends StatelessWidget {
  const PetConnectApp({super.key});

  Future<Map<String, dynamic>?> _getProfileData(String userId) async {
    final supabase = Supabase.instance.client;
    final profileResponse = await supabase
        .from('profiles')
        .select() // Select all profile fields
        .eq('user_id', userId)
        .maybeSingle();

    return profileResponse;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Connect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData && snapshot.data?.session != null) {
            return FutureBuilder<Map<String, dynamic>?>(
              future: _getProfileData(snapshot.data!.session!.user.id),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }

                final profile = userSnapshot.data;
                final user = snapshot.data!.session!.user;
                final provider = user.appMetadata['provider'];

                // For social logins, if profile is incomplete, go to setup screen.
                if (provider != 'email' && (profile == null || profile['first_name'] == null || profile['first_name'].isEmpty)) {
                  return const SocialProfileSetupScreen();
                }

                // For all users, if role is not set, go to role selection.
                if (profile == null || profile['role'] == null || (profile['role'] as String).isEmpty) {
                  return const RoleSelectionScreen();
                }

                final userRole = profile['role'];


                // Navigate based on role.
                if (userRole == 'Pet Owner') {
                  return const MainScreen();
                } else if (userRole == 'Vet') {
                  return const VetHomeScreen();
                } else if (userRole == 'Shelter Owner') {
                  return const ShelterHomeScreen();
                } else {
                  // Default fallback
                  return const RoleSelectionScreen();
                }
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
        ManagePetsScreen.routeName: (context) => const ManagePetsScreen(),
        AdoptionRequestsScreen.routeName: (context) => const AdoptionRequestsScreen(),
        ShelterProfileScreen.routeName: (context) => const ShelterProfileScreen(),
        EditProfileScreen.routeName: (context) => const EditProfileScreen(),
        SocialProfileSetupScreen.routeName: (context) => const SocialProfileSetupScreen(),
        MapScreen.routeName: (context) => const MapScreen(),
        ProfileDetailsScreen.routeName: (context) => const ProfileDetailsScreen(),
        AddEditMedicalNoteScreen.routeName: (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final petId = args?['petId'] as String;
          final note = args?['note'] as MedicalNote?;
          return AddEditMedicalNoteScreen(petId: petId, note: note);
        },
      },
    );
  }
}