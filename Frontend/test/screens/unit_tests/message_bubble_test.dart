import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_connect_app/screens/chat_screen.dart';

void main() {
  group('MessageBubble Widget Tests', () {
    
    testWidgets('displays the message content correctly', (WidgetTester tester) async {
      // 1. Arrange: Define the fake message text
      const String testMessage = 'Hi, I want to adopt this pet!';

      // 2. Act: Build the MessageBubble widget inside a blank dummy app
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              content: testMessage,
              isMe: true, // Simulating a sent message
            ),
          ),
        ),
      );

      // 3. Assert: Verify that the text appears exactly as expected on the screen
      expect(find.text(testMessage), findsOneWidget);
    });
  });
}