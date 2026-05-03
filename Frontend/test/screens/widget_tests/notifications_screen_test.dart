import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_connect_app/screens/notifications_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    // Setup a dummy Supabase instance so the test doesn't crash when
    // NotificationsScreen attempts to fetch notifications on startup.
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

  group('NotificationsScreen Simple Widget Tests', () {
    testWidgets('1. Should render the main Scaffold and AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('2. Should display a loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}