import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_connect_app/screens/login_screen.dart';

void main() {
  group('LoginScreen Simple Widget Tests', () {
    
    testWidgets('1. Should render the main Scaffold structure', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      // Verifies that the LoginScreen uses a Scaffold as its base container
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('2. Should render at least one TextField for user input', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      // Verifies that text fields (such as email/password) are present on the screen
      expect(find.byType(TextField), findsWidgets);
    });
  });
}