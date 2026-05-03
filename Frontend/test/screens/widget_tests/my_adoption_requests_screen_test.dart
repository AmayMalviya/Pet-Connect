import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_connect_app/screens/my_adoption_requests_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    // Setup a dummy Supabase instance so the test doesn't crash if the screen 
    // attempts to initialize or read from Supabase on startup.
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://mock.supabase.co',
      anonKey: 'mock-anon-key',
    );
  });

  group('MyAdoptionRequestsScreen Simple Widget Tests', () {
    
    testWidgets('1. Should render the main Scaffold structure', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MyAdoptionRequestsScreen()));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('2. Should render an AppBar for navigation', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MyAdoptionRequestsScreen()));

      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}