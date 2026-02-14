import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pet_connect_app/screens/adoption_screen.dart';
import 'package:pet_connect_app/screens/health_details_screen.dart';
import 'package:pet_connect_app/screens/services_screen.dart';

import 'services_screen_test.mocks.dart';

@GenerateMocks([NavigatorObserver])
void main() {
  testWidgets('ServicesScreen navigation test', (WidgetTester tester) async {
    final mockObserver = MockNavigatorObserver();

    await tester.pumpWidget(MaterialApp(
      home: const ServicesScreen(),
      routes: {
        HealthDetailsScreen.routeName: (_) => const Scaffold(),
        AdoptionScreen.routeName: (_) => const Scaffold(),
      },
      navigatorObservers: [mockObserver],
    ));

    // Verify that the initial screen is the ServicesScreen
    expect(find.byType(ServicesScreen), findsOneWidget);

    // Tap the 'Health Track' card
    await tester.tap(find.widgetWithText(ServiceCard, 'Health Track'));
    await tester.pumpAndSettle();

    // Verify that a push navigation event to HealthDetailsScreen occurred
    verify(mockObserver.didPush(any, any));
    expect(find.byType(Scaffold), findsOneWidget); // We pushed a Scaffold in the route

    // Tap the 'Adoption' card
    await tester.tap(find.widgetWithText(ServiceCard, 'Adoption'));
    await tester.pumpAndSettle();

    // Verify that a push navigation event to AdoptionScreen occurred
    verify(mockObserver.didPush(any, any));
    expect(find.byType(Scaffold), findsNWidgets(1)); // We pushed a Scaffold in the route
  });
}
