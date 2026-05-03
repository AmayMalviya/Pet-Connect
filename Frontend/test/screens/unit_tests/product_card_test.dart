import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_connect_app/models/product.dart';
import 'package:pet_connect_app/screens/shop_screen.dart';

void main() {
  testWidgets('ProductCard displays product details correctly', (WidgetTester tester) async {
    // 1. Arrange: Create a dummy product
    final dummyProduct = Product(
      id: 'prod_99',
      name: 'Tasty Cat Treats',
      price: '\$12.99',
      imageUrl: '', // Passing empty to avoid network calls during tests
      productUrl: 'https://example.com/treats',
    );

    // 2. Act: "Pump" (build) the widget inside a dummy MaterialApp environment
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductCard(product: dummyProduct),
        ),
      ),
    );

    // 3. Assert: Check if the UI renders the correct text and icons
    expect(find.text('Tasty Cat Treats'), findsOneWidget);
    expect(find.text('\$12.99'), findsOneWidget);
    expect(find.byIcon(Icons.add_shopping_cart), findsOneWidget);
    
    // Verify that a random text is NOT on the screen
    expect(find.text('Premium Dog Food'), findsNothing);
  });
}