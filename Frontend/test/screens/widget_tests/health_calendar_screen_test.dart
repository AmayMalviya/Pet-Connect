import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_connect_app/screens/health_details_screen.dart';

void main() {
  group('HealthDetailsScreen Simple Widget Tests', () {
    
    testWidgets('1. Should render Scaffold and "No pet selected" fallback', (WidgetTester tester) async {
      // Passing no arguments leaves petId as null, safely triggering the fallback UI without needing Supabase
      await tester.pumpWidget(const MaterialApp(home: HealthDetailsScreen()));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('No pet selected'), findsOneWidget);
    });

    testWidgets('2. Should render an AppBar for calendar navigation', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HealthDetailsScreen()));

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Health Calendar'), findsOneWidget);
    });
  });
}