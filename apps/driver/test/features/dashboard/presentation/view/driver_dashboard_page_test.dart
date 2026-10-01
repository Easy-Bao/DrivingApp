import 'package:driver/src/features/dashboard/presentation/view/driver_dashboard_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('status pulse runs only while online in the foreground', () {
    expect(
      shouldAnimateDriverStatusPulse(isOnline: false, isForeground: true),
      isFalse,
    );
    expect(
      shouldAnimateDriverStatusPulse(isOnline: true, isForeground: false),
      isFalse,
    );
    expect(
      shouldAnimateDriverStatusPulse(isOnline: true, isForeground: true),
      isTrue,
    );
  });
}
