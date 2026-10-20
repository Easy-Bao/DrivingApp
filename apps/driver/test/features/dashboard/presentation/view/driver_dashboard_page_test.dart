import 'package:driver/src/features/dashboard/presentation/view/driver_dashboard_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('status pulse runs only while online in the foreground', () {
    expect(
      shouldAnimateStatusPulse(isOnline: false, isForeground: true),
      isFalse,
    );
    expect(
      shouldAnimateStatusPulse(isOnline: true, isForeground: false),
      isFalse,
    );
    expect(
      shouldAnimateStatusPulse(isOnline: true, isForeground: true),
      isTrue,
    );
  });
}
