import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_connect_app/screens/shelter_verification_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    // Mock Supabase and SharedPreferences as the screen likely uses them
    // for user data and submitting verification info.
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://mock.supabase.co',
      anonKey: 'mock-anon-key',
    );
  });

  tearDownAll(() async {
    // Dispose the Supabase client to prevent timer leaks.
    await Supabase.instance.client.dispose();
  });

  group('ShelterVerificationScreen Simple Widget Tests', () {
    testWidgets('1. Should render the main Scaffold and AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ShelterVerificationScreen()));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('2. Should render input fields and a submit button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ShelterVerificationScreen()));

      expect(find.byType(TextField), findsWidgets);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}