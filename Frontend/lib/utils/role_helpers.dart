import 'package:flutter/material.dart';

/// Small helpers related to roles so UI and tests can reuse them.
IconData getIconForRole(String roleName) {
  switch (roleName) {
    case 'Pet Owner':
      return Icons.person_outline;
    case 'Shelter Owner':
      return Icons.home_outlined;
    case 'Vet':
      return Icons.medical_services_outlined;
    default:
      return Icons.person;
  }
}
