class AadhaarValidator {
  static const List<List<int>> _multiplicationTable = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 2, 3, 4, 0, 6, 7, 8, 9, 5],
    [2, 3, 4, 0, 1, 7, 8, 9, 5, 6],
    [3, 4, 0, 1, 2, 8, 9, 5, 6, 7],
    [4, 0, 1, 2, 3, 9, 5, 6, 7, 8],
    [5, 9, 8, 7, 6, 0, 4, 3, 2, 1],
    [6, 5, 9, 8, 7, 1, 0, 4, 3, 2],
    [7, 6, 5, 9, 8, 2, 1, 0, 4, 3],
    [8, 7, 6, 5, 9, 3, 2, 1, 0, 4],
    [9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
  ];

  static const List<List<int>> _permutationTable = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 5, 7, 6, 2, 8, 3, 0, 9, 4],
    [5, 8, 0, 3, 7, 9, 6, 1, 4, 2],
    [8, 9, 1, 6, 0, 4, 3, 5, 2, 7],
    [9, 4, 5, 3, 1, 2, 6, 8, 7, 0],
    [4, 2, 8, 6, 5, 7, 3, 9, 0, 1],
    [2, 7, 9, 3, 8, 0, 6, 4, 1, 5],
    [7, 0, 4, 6, 9, 1, 3, 2, 5, 8],
  ];

  static const List<int> _inverseTable = [0, 4, 3, 2, 1, 5, 6, 7, 8, 9];

  /// Validates a 12-digit Aadhaar number using the Verhoeff algorithm.
  static bool validate(String aadhaar) {
    // Remove space/hyphens
    final cleaned = aadhaar.replaceAll(RegExp(r'[\s-]'), '');
    
    if (cleaned.length != 12 || !RegExp(r'^\d{12}$').hasMatch(cleaned)) {
      return false;
    }

    final digits = cleaned.split('').map(int.parse).toList();
    int checksum = 0;

    for (int i = 0; i < digits.length; i++) {
      final index = i % 8;
      final digit = digits[digits.length - 1 - i];
      checksum = _multiplicationTable[checksum][_permutationTable[index][digit]];
    }

    return checksum == 0;
  }

  /// Masks an Aadhaar number to show only last 4 digits: XXXX-XXXX-1234
  static String mask(String aadhaar) {
    final cleaned = aadhaar.replaceAll(RegExp(r'[\s-]'), '');
    if (cleaned.length < 4) return cleaned;
    
    final last4 = cleaned.substring(cleaned.length - 4);
    return 'XXXX-XXXX-$last4';
  }

// Only store the last 4 digits in the database — never the full number
  static String safeStore(String number) {
    if (number.length != 12) return '';
    return 'XXXXXXXX${number.substring(8)}';
  }
}
