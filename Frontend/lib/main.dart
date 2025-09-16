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
            return const MainScreen();
          } else {
            return const AuthScreen();
          }
        },
      ),
      routes: {
        AuthScreen.routeName: (_) => const AuthScreen(),
        LoginScreen.routeName: (_) => const LoginScreen(),
        RegisterScreen.routeName: (_) => const RegisterScreen(),
        ProfileScreen.routeName: (_) => const ProfileScreen(),
        MainScreen.routeName: (_) => const MainScreen(),
        AddPetScreen.routeName: (_) => const AddPetScreen(),
        SelfCareOptionsScreen.routeName: (_) => SelfCareOptionsScreen(),
        HealthDetailsScreen.routeName: (_) => HealthDetailsScreen(),
        ServicesScreen.routeName: (_) => ServicesScreen(),
        ShopScreen.routeName: (_) => ShopScreen(),
        GroomingDetailsScreen.routeName: (_) => GroomingDetailsScreen(),
        TrainingDetailsScreen.routeName: (_) => TrainingDetailsScreen(),
        VetDetailsScreen.routeName: (_) => VetDetailsScreen(),
        NutritionAdviceScreen.routeName: (_) => NutritionAdviceScreen(),
      },
    );
  }
}

