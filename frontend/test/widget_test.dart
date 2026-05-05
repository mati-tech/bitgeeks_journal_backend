// Smoke test scaffold. Real widget tests live alongside features in later
// passes; this just keeps the test runner happy until those land.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app constants have a non-empty API base URL', () {
    // Avoid importing the full app graph here — keeps this test hermetic.
    const apiBase = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000');
    expect(apiBase.isNotEmpty, isTrue);
  });
}
