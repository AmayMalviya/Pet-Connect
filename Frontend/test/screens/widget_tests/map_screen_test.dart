import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_connect_app/screens/map_screen.dart';

void main() {
  group('MapScreen Simple Widget Tests', () {
    
    testWidgets('1. Should render the main Scaffold structure', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MapScreen()));

      // Simply verifies that the MapScreen uses a Scaffold as its base
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('2. Should render an AppBar for navigation', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: MapScreen()));

      // Verifies that an AppBar is present at the top of the map screen
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}