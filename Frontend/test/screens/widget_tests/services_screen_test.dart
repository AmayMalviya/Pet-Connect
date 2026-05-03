import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_connect_app/screens/services_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    // Initialize a dummy Supabase instance so the test doesn't crash 
    // when ServicesScreen attempts to read the currentUser in initState.
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://mock.supabase.co',
      anonKey: 'mock-anon-key',
    );
  });

  group('ServicesScreen Simple Widget Tests', () {
    
    testWidgets('1. Should render the main Scaffold and ScrollView structure', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ServicesScreen()));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('2. Should render premium banner and service section titles', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ServicesScreen()));

      expect(find.text('Pet Care'), findsOneWidget);
      expect(find.text('Explore Services'), findsOneWidget);
    });
  });
}