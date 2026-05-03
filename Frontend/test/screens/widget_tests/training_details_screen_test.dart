import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_connect_app/screens/training_details_screen.dart';

void main() {
  group('TrainingDetailsScreen Simple Widget Tests', () {
    
    testWidgets('1. Should render the main Scaffold and AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TrainingDetailsScreen()));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Training Details'), findsOneWidget);
    });

    testWidgets('2. Should display the training details text and back button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: TrainingDetailsScreen()));

      // Verifies the content body text and the leading back button exist
      expect(find.text('Details about Training services.'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
    });
  });
}