import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pet_connect_app/screens/adoption_screen.dart';
import 'package:pet_connect_app/screens/health_details_screen.dart';
import 'package:pet_connect_app/screens/services_screen.dart';

// Simple mock for NavigatorObserver used in widget tests.
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  testWidgets('ServicesScreen navigation test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const ServicesScreen(),
        routes: {
          HealthDetailsScreen.routeName: (_) => const Scaffold(),
          AdoptionScreen.routeName: (_) => const Scaffold(),
        },
      ),
    );

    // Verify that the initial screen is the ServicesScreen
    expect(find.byType(ServicesScreen), findsOneWidget);

    // Tap the 'Health Track' card and ensure navigation occurs
    await tester.tap(find.text('Health Track'));
    await tester.pumpAndSettle();
    expect(find.byType(Scaffold), findsOneWidget);

    // Tap the 'Adoption' card and ensure navigation occurs
    await tester.tap(find.text('Adoption'));
    await tester.pumpAndSettle();
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
