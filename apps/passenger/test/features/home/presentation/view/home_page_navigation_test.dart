import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/home/presentation/view/home_page.dart';

void main() {
  test('allows one Home route entry until the first one returns', () {
    expect(
      shouldStartHomeNavigation(isMounted: true, isNavigationInFlight: false),
      isTrue,
    );
    expect(
      shouldStartHomeNavigation(isMounted: true, isNavigationInFlight: true),
      isFalse,
    );
    expect(
      shouldStartHomeNavigation(isMounted: false, isNavigationInFlight: false),
      isFalse,
    );
  });
}
