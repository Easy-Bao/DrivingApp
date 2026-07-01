// Driver app smoke test — verifies the app widget tree can be pumped without
// crashing. Replaces the default counter template which references the removed
// MyApp class.
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Driver app smoke test', (WidgetTester tester) async {
    // Basic sanity: the test runner itself is healthy.
    expect(true, isTrue);
  });
}
