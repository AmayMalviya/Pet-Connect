import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_connect_app/screens/shop_screen.dart';
import 'package:pet_connect_app/models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  // Setup a dummy Supabase instance so the test doesn't crash when ShopScreen 
  // attempts to initialize the SupabaseService.
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://mock.supabase.co',
      anonKey: 'mock-anon-key',
    );
  });

  group('ShopScreen Widget Tests', () {
    testWidgets('1. Should display AppBar, BackButton, and initial loading state', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ShopScreen()));

      // Verify standard AppBar elements
      expect(find.text('Shop'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      
      // Verify the loading indicator is shown initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('2. Should render search bar structure after loading finishes', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ShopScreen()));
      await tester.pumpAndSettle(); // Waits for the initial async load to finish

      // Verify the search field and its decorations exist
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search products...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('3. Should allow user to type in the search bar', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ShopScreen()));
      await tester.pumpAndSettle(); // Waits for the initial async load to finish

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Dog Toy');
      await tester.pump();

      expect(find.text('Dog Toy'), findsOneWidget);
    });

    testWidgets('4. Should display empty list when no products are returned', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ShopScreen()));
      await tester.pumpAndSettle(); 

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(ProductCard), findsNothing);
    });
  });

  group('ProductCard Widget Tests', () {
    final testProduct = Product(
      id: 'prod_001',
      name: 'Premium Dog Food',
      price: '\$25.99',
      imageUrl: 'https://example.com/image.png',
    );

    testWidgets('5. Should display product details and cart icon correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: testProduct),
          ),
        ),
      );

      expect(find.text('Premium Dog Food'), findsOneWidget);
      expect(find.text('\$25.99'), findsOneWidget);
      expect(find.byIcon(Icons.add_shopping_cart), findsOneWidget);
      expect(find.byType(Image), findsOneWidget); // Verifies the image widget is in the tree
    });

    testWidgets('6. Should disable tap interaction if productUrl is missing', (WidgetTester tester) async {
      final noUrlProduct = Product(
        id: 'prod_002',
        name: 'Catnip',
        price: '\$5.00',
        imageUrl: 'https://example.com/catnip.png',
      ); // productUrl defaults to null

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: ProductCard(product: noUrlProduct))),
      );

      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.onTap, isNull);
    });

    testWidgets('7. Should have a clickable Add to Cart button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductCard(product: testProduct),
          ),
        ),
      );

      final cartButton = find.byIcon(Icons.add_shopping_cart);
      expect(cartButton, findsOneWidget);

      // Simulate user tap. It should execute the empty onPressed: () {} without crashing.
      await tester.tap(cartButton);
      await tester.pump();
    });
  });
}