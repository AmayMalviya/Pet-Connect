import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_connect_app/screens/pet_care_ai_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pet_connect_app/models/pet.dart';

// A dummy Pet class to satisfy the non-nullable Pet parameter requirement
class DummyPet extends Fake implements Pet {
  @override
  String get name => 'Buddy';
  @override
  String get animal => 'Dog';
}

void main() {
  setUpAll(() {
    // Mock SharedPreferences as AIService uses it for caching conversations
    SharedPreferences.setMockInitialValues({});
  });

  group('PetCareAIScreen Simple Widget Tests', () {
    
    testWidgets('1. Should render the Scaffold and AppBar with the correct topic title', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PetCareAIScreen(
          pet: DummyPet(),
          topic: 'grooming',
          topicTitle: 'Grooming Tips',
        ),
      ));

      // Verifies that the screen builds its core structure and displays the topic title
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Grooming Tips'), findsOneWidget);
    });

    testWidgets('2. Should render a TextField for asking AI questions', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PetCareAIScreen(
          pet: DummyPet(),
          topic: 'diet',
          topicTitle: 'Diet & Nutrition',
        ),
      ));

      // Verifies that the input field for user questions is present
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}