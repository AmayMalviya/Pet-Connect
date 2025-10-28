import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_connect_app/screens/role_selection_screen.dart';

void main() {
  test('getIconForRole returns expected icons', () {
    expect(getIconForRole('Pet Owner'), Icons.person_outline);
    expect(getIconForRole('Shelter Owner'), Icons.home_outlined);
    expect(getIconForRole('Vet'), Icons.medical_services_outlined);
    expect(getIconForRole('Unknown Role'), Icons.person);
  });
}
