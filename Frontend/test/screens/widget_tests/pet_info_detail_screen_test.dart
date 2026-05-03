import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_connect_app/screens/pet_info_detail_screen.dart';
import 'package:pet_connect_app/models/pet.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A dummy Pet class to satisfy the non-nullable Pet parameter requirement
class DummyPet extends Fake implements Pet {
  @override
  String? get name => 'Buddy';
}

void main() {
  setUpAll(() {
    // Mock SharedPreferences as AIService requires it during initialization
    SharedPreferences.setMockInitialValues({});
  });

  group('PetInfoDetailScreen Simple Widget Tests', () {
    testWidgets('1. Should render the main Scaffold and display title/content', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PetInfoDetailScreen(
          title: 'Diet Info',
          content: 'This is some important info about your pet diet.',
          pet: DummyPet(),
          topic: 'Diet',
        ),
      ));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Diet Info'), findsWidgets); // Will be found in AppBar and the body header
      expect(find.text('This is some important info about your pet diet.'), findsOneWidget);
    });

    testWidgets('2. Should display AI Assistant input field and button', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PetInfoDetailScreen(
          title: 'Grooming',
          content: 'Brush daily.',
          pet: DummyPet(),
          topic: 'Grooming',
        ),
      ));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Ask AI'), findsOneWidget);
    });
  });
}