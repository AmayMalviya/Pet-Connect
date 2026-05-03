import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_connect_app/screens/pet_dashboard_screen.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// A dummy Pet class to satisfy the non-nullable Pet parameter requirement
class DummyPet extends Fake implements Pet {
  @override
  String? get id => 'dummy_pet_123';
  
  @override
  String? get name => 'Buddy';
  
  @override
  String? get photoUrl => null; // Returning null prevents network image errors during testing
}

void main() {
  setUpAll(() async {
    // Setup a dummy Supabase instance so the test doesn't crash when
    // PetDashboardScreen attempts to fetch breed info on startup.
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://mock.supabase.co',
      anonKey: 'mock-anon-key',
    );
  });

  tearDownAll(() async {
    // Dispose the Supabase client to close any open connections and prevent timer leaks.
    await Supabase.instance.client.dispose();
  });

  group('PetDashboardScreen Simple Widget Tests', () {
    testWidgets('1. Should render the main Scaffold and AppBar with pet name', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: PetDashboardScreen(pet: DummyPet())));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text("Buddy's Dashboard"), findsOneWidget); // Verifies the pet name displays in the AppBar
    });

    testWidgets('2. Should display a loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: PetDashboardScreen(pet: DummyPet())));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}