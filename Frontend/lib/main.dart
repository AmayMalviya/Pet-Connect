import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pet_connect_app/firebase_options.dart';

import 'package:pet_connect_app/screens/admin/admin_kyc_approval_screen.dart';
import 'package:pet_connect_app/screens/auth_state_handler.dart';
import 'package:pet_connect_app/screens/kyc_personal_screen.dart';
import 'package:pet_connect_app/screens/main_screen.dart';
import 'package:pet_connect_app/screens/shelter_adoption_requests_screen.dart';
import 'package:pet_connect_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'package:pet_connect_app/screens/self_care_options_screen.dart';
import 'package:pet_connect_app/screens/services_screen.dart';
import 'package:pet_connect_app/screens/grooming_details_screen.dart';
import 'package:pet_connect_app/screens/training_details_screen.dart';
import 'package:pet_connect_app/screens/nutrition_advice_screen.dart';
import 'package:pet_connect_app/screens/role_selection_screen.dart';
import 'package:pet_connect_app/screens/kyc_document_screen.dart';
import 'package:pet_connect_app/screens/kyc_pending_screen.dart';
import 'package:pet_connect_app/screens/kyc_screen.dart';
import 'package:pet_connect_app/screens/verification_success_screen.dart';
import 'package:pet_connect_app/screens/under_review_screen.dart';
import 'package:pet_connect_app/screens/shelter_home_screen.dart';
import 'package:pet_connect_app/screens/appointments_screen.dart';
import 'package:pet_connect_app/screens/shelter/manage_pets_screen.dart';
import 'package:pet_connect_app/screens/adoption_requests_screen.dart';
import 'package:pet_connect_app/screens/shelter_profile_screen.dart';
import 'package:pet_connect_app/screens/edit_profile_screen.dart';
import 'package:pet_connect_app/screens/social_profile_setup_screen.dart';
import 'package:pet_connect_app/screens/map_screen.dart';
import 'package:pet_connect_app/screens/profile_details_screen.dart';
import 'package:pet_connect_app/screens/add_edit_medical_note_screen.dart';
import 'package:pet_connect_app/models/medical_note.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pet_connect_app/screens/shelter/manage_appointments_screen.dart';
import 'package:pet_connect_app/screens/shelter/shelter_analytics_screen.dart';
import 'package:pet_connect_app/screens/admin/admin_dashboard_screen.dart';
import 'package:pet_connect_app/screens/admin/manage_profiles_screen.dart';
import 'package:pet_connect_app/screens/admin/approve_verifications_screen.dart';
import 'package:pet_connect_app/screens/admin/manage_community_screen.dart';
import 'package:pet_connect_app/screens/admin/admin_analytics_screen.dart';
import 'package:pet_connect_app/screens/notifications_screen.dart';
import 'package:pet_connect_app/screens/adoption_screen.dart';
import 'package:pet_connect_app/screens/health_details_screen.dart';
import 'package:pet_connect_app/screens/reset_password_screen.dart';
import 'package:pet_connect_app/services/notification_service.dart';
import 'package:app_links/app_links.dart';
import 'screens/auth_callback_screen.dart';

final notificationService = NotificationService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  // We MUST initialize Supabase before runApp because the UI needs it immediately
  await Supabase.initialize(
    url: 'https://goegjrqmyshnzzonfjav.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdvZWdqcnFteXNobnp6b25mamF2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc0OTMyOTAsImV4cCI6MjA3MzA2OTI5MH0.i4KPxTg_d85Pd8vXMdOYxvoHdrVDZNmGaz30x1ZBglU',
  );

  runApp(const PetConnectApp());

  // Initialize heavy services (like Firebase/Notifications) in the background so they don't block startup
  _initializeServices();
}

Future<void> _initializeServices() async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await notificationService.init();
    
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        debugPrint('User logged in');
      }
    });
  } catch (e) {
    debugPrint('Error during background initialization: \$e');
  }
}

class PetConnectApp extends StatefulWidget {
  const PetConnectApp({super.key});

  @override
  State<PetConnectApp> createState() => _PetConnectAppState();
}

class _PetConnectAppState extends State<PetConnectApp> {
  final _appLinks = AppLinks();
  late final StreamSubscription<Uri> _linkSubscription;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription.cancel();
    super.dispose();
  }

  void _initDeepLinks() async {
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null && initialUri.scheme == 'io.supabase.petconnect') {
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleDeepLink(initialUri);
        });
      }
    } catch (e) {}
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'io.supabase.petconnect') {
      _navigatorKey.currentState?.pushNamed(AuthCallbackScreen.routeName, arguments: uri);
    }
  }

  Future<Map<String, dynamic>?> _getProfileData(String userId) async {
    final supabase = Supabase.instance.client;
    final profileResponse = await supabase
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    return profileResponse;
  }

  Widget _guardShelterRoute(Widget page) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getProfileData(Supabase.instance.client.auth.currentUser!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final profile = snapshot.data;
        final userRole = profile?['role'] as String?;

        if (userRole == null ||
            (userRole != 'Shelter' && userRole != 'Shelter Owner')) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigatorKey.currentState?.pushReplacementNamed(RoleSelectionScreen.routeName);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return page;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Pet Connect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AuthStateHandler(
        child: StreamBuilder<AuthState>(
          stream: Supabase.instance.client.auth.onAuthStateChange,
          builder: (context, snapshot) {
            final session = Supabase.instance.client.auth.currentSession;
            
            // If we have a session, we're logged in
            if (session != null) {
              final user = session.user;

              if (user.email == 'malviyaamay501@gmail.com') {
                return const AdminDashboardScreen();
              }

              return FutureBuilder<Map<String, dynamic>?>(
                future: _getProfileData(user.id),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final profile = userSnapshot.data;
                  final provider = user.appMetadata['provider'];

                  if (provider != 'email' &&
                      (profile == null ||
                          profile['first_name'] == null ||
                          profile['first_name'].isEmpty)) {
                    return const SocialProfileSetupScreen();
                  }

                  if (profile == null ||
                      profile['role'] == null ||
                      (profile['role'] as String).isEmpty) {
                    return const RoleSelectionScreen();
                  }

                  final userRole = profile['role'];

                  if (userRole == 'Pet Owner') {
                    return const MainScreen();
                  } else if (userRole == 'Shelter' ||
                      userRole == 'Shelter Owner') {
                    final kycVerified = profile['kyc_verified'] == true;
                    if (kycVerified) {
                      return const ShelterHomeScreen();
                    } else {
                      return const KycScreen();
                    }
                  } else {
                    return const RoleSelectionScreen();
                  }
                },
              );
            }
            
            // Fallback for loading state or no session
            if (snapshot.connectionState == ConnectionState.waiting && session == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return const AuthScreen();
          },
        ),
      ),
      routes: {
        AuthScreen.routeName: (context) => const AuthScreen(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        RegisterScreen.routeName: (context) => const RegisterScreen(),
        AuthCallbackScreen.routeName: (context) => const AuthCallbackScreen(),
        ResetPasswordScreen.routeName: (context) {
          final session = ModalRoute.of(context)!.settings.arguments as Session;
          return ResetPasswordScreen(session: session);
        },
        ProfileScreen.routeName: (context) => const ProfileScreen(),
        MainScreen.routeName: (context) => const MainScreen(),
        SelfCareOptionsScreen.routeName: (context) => const SelfCareOptionsScreen(),
        ServicesScreen.routeName: (context) => const ServicesScreen(),
        GroomingDetailsScreen.routeName: (context) => const GroomingDetailsScreen(),
        TrainingDetailsScreen.routeName: (context) => const TrainingDetailsScreen(),
        NutritionAdviceScreen.routeName: (context) => const NutritionAdviceScreen(),
        RoleSelectionScreen.routeName: (context) => const RoleSelectionScreen(),
        KycDocumentScreen.routeName: (context) => const KycDocumentScreen(),
        KycPendingScreen.routeName: (context) => const KycPendingScreen(),
        KycPersonalScreen.routeName: (context) => const KycPersonalScreen(),
        KycScreen.routeName: (context) => const KycScreen(),
        VerificationSuccessScreen.routeName: (context) => const VerificationSuccessScreen(),
        UnderReviewScreen.routeName: (context) => const UnderReviewScreen(),
        ShelterHomeScreen.routeName: (context) => _guardShelterRoute(const ShelterHomeScreen()),
        AppointmentsScreen.routeName: (context) => _guardShelterRoute(const AppointmentsScreen()),
        ManagePetsScreen.routeName: (context) => _guardShelterRoute(const ManagePetsScreen()),
        AdoptionRequestsScreen.routeName: (context) => _guardShelterRoute(const AdoptionRequestsScreen()),
        ShelterProfileScreen.routeName: (context) => _guardShelterRoute(const ShelterProfileScreen()),
        EditProfileScreen.routeName: (context) => const EditProfileScreen(),
        SocialProfileSetupScreen.routeName: (context) => const SocialProfileSetupScreen(),
        AdminDashboardScreen.routeName: (_) => const AdminDashboardScreen(),
        AdminKycApprovalScreen.routeName: (_) => const AdminKycApprovalScreen(),
        MapScreen.routeName: (context) => const MapScreen(),
        ProfileDetailsScreen.routeName: (context) => const ProfileDetailsScreen(),
        AdoptionScreen.routeName: (context) => const AdoptionScreen(),
        HealthDetailsScreen.routeName: (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final petId = args?['petId'] as String?;
          return HealthDetailsScreen(petId: petId);
        },
        AddEditMedicalNoteScreen.routeName: (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final petId = args?['petId'] as String;
          final note = args?['note'] as MedicalNote?;
          return AddEditMedicalNoteScreen(petId: petId, note: note);
        },
        ManageAppointmentsScreen.routeName: (context) => _guardShelterRoute(const ManageAppointmentsScreen()),
        ShelterAnalyticsScreen.routeName: (context) => _guardShelterRoute(const ShelterAnalyticsScreen()),
        ShelterAdoptionRequestsScreen.routeName: (_) => _guardShelterRoute(const ShelterAdoptionRequestsScreen()),
        ManageProfilesScreen.routeName: (context) => const ManageProfilesScreen(),
        ManageCommunityScreen.routeName: (context) => const ManageCommunityScreen(),
        ApproveVerificationsScreen.routeName: (context) => const ApproveVerificationsScreen(),
        AdminAnalyticsScreen.routeName: (context) => const AdminAnalyticsScreen(),
        NotificationsScreen.routeName: (context) => const NotificationsScreen(),
      },
    );
  }
}
