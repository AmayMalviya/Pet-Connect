import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_connect_app/screens/shop_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    // Mock SharedPreferences so Supabase doesn't crash trying to access local storage in a test
    SharedPreferences.setMockInitialValues({});
    
    // Initialize a dummy Supabase instance to satisfy the dependency without making real calls
    await Supabase.initialize(
      url: 'https://mock.supabase.co',
      anonKey: 'mock-anon-key',
    );
  });

  group('ShopScreen Widget Tests', () {
    
    testWidgets('Should display AppBar and CircularProgressIndicator on initial load', (WidgetTester tester) async {
      // Pump the widget inside a MaterialApp structure
      await tester.pumpWidget(
        const MaterialApp(
          home: ShopScreen(),
        ),
      );

      // 1. Verify the AppBar Title exists
      expect(find.text('Shop'), findsOneWidget);

      // 2. Verify the BackButton exists in the leading position
      expect(find.byType(BackButton), findsOneWidget);

      // 3. Verify the loading state is active initially
      // Because _isLoading is set to true by default, the screen should immediately
      // render a CircularProgressIndicator while waiting for _loadProducts().
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}