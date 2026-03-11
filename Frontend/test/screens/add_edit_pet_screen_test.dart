
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_connect_app/screens/add_edit_pet_screen.dart';

void main() {
  testWidgets('AddEditPetScreen has a title and form fields', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: AddEditPetScreen()));

    // Verify that the title is displayed
    expect(find.text('Add/Edit Pet'), findsOneWidget);

    // Verify that the form fields are present
    expect(find.byType(TextFormField), findsNWidgets(10)); // Adjust the count based on the number of fields
    expect(find.byType(DropdownButtonFormField), findsNWidgets(2)); // Adjust based on dropdowns
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
