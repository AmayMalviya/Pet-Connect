import 'package:flutter/material.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://goegjrqmyshnzzonfjav.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdvZWdqcnFteXNobnp6b25mamF2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc0OTMyOTAsImV4cCI6MjA3MzA2OTI5MH0.i4KPxTg_d85Pd8vXMdOYxvoHdrVDZNmGaz30x1ZBglU',
  );
  runApp(const PetConnectApp());
}

class PetConnectApp extends StatelessWidget {
  const PetConnectApp({super.key});

  Future<String?> _getUserRole(String userId) async {
    final supabase = Supabase.instance.client;
    final profileResponse = await supabase
        .from('profiles')
        .select('role_id')
        .eq('user_id', userId)
        .single();

    if (profileResponse.isEmpty || profileResponse['role_id'] == null) {
      return null;
    }

    final roleId = profileResponse['role_id'];
    final roleResponse = await supabase
        .from('roles')
        .select('name')
        .eq('id', roleId)
        .single();

    return roleResponse['name'] as String?;
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
            return FutureBuilder<String?>(
              future: _getUserRole(snapshot.data!.session!.user.id),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                if (userSnapshot.hasData) {
                  final userRole = userSnapshot.data;
                  if (userRole == 'Pet Owner') {
                    return const MainScreen();
                  } else if (userRole == 'Vet') {
                    return const VetHomeScreen();
                  } else if (userRole == 'Shelter Owner') {
                    return const ShelterHomeScreen();
                  } else {
                    return const RoleSelectionScreen();
                  }
                } else {
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
        ManagePetsScreen.routeName: (context) => const ManagePetsScreen(),
        AdoptionRequestsScreen.routeName: (context) => const AdoptionRequestsScreen(),
        ShelterProfileScreen.routeName: (context) => const ShelterProfileScreen(),
      },
    );
  }
}