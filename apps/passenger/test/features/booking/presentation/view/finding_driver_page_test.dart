import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/booking/presentation/view/finding_driver_page.dart';

void main() {
  test('allows only one home navigation while cancellation is settling', () {
    expect(
      shouldStartFindingDriverHomeNavigation(
        isMounted: true,
        isNavigationInFlight: false,
      ),
      isTrue,
    );
    expect(
      shouldStartFindingDriverHomeNavigation(
        isMounted: true,
        isNavigationInFlight: true,
      ),
      isFalse,
    );
    expect(
      shouldStartFindingDriverHomeNavigation(
        isMounted: false,
        isNavigationInFlight: false,
      ),
      isFalse,
    );
  });
}
