import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_connect_app/screens/community_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    // Setup a dummy Supabase instance so the test doesn't crash when
    // CommunityScreen attempts to initialize the posts stream on startup.
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

  group('CommunityScreen Simple Widget Tests', () {
    
    testWidgets('1. Should render the main Scaffold and FloatingActionButton', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CommunityScreen()));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('2. Should display a loading indicator while fetching posts', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CommunityScreen()));

      // Verifies that a CircularProgressIndicator is shown initially while the StreamBuilder waits for data
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}