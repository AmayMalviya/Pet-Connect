import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_connect_app/screens/main_screen.dart';

void main() {
  group('MainScreen Simple Widget Tests', () {
    
    testWidgets('1. Should render the main Scaffold structure', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainScreen()));

      // Verifies that the MainScreen uses a Scaffold as its base container
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('2. Should render a FloatingActionButton for AI features', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MainScreen()));

      // Verifies that a FloatingActionButton is present (the Pet AI button)
      expect(find.byType(FloatingActionButton), findsWidgets);
    });
  });
}