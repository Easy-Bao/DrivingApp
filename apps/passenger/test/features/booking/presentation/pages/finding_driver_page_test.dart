import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/booking/presentation/pages/finding_driver_page.dart';

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

  test('parses route duration strings including hours and minutes', () {
    expect(parseRouteDurationMinutes('1 hr 15 min'), 75);
    expect(parseRouteDurationMinutes('2 hrs 5 mins'), 125);
    expect(parseRouteDurationMinutes('1 hr'), 60);
    expect(parseRouteDurationMinutes('12 min'), 12);
    expect(parseRouteDurationMinutes('4.5 mins'), 4.5);
    expect(parseRouteDurationMinutes(''), isNull);
  });

  test('parses route distance strings in kilometers and meters', () {
    expect(parseRouteDistanceKm('2.4 km'), 2.4);
    expect(parseRouteDistanceKm('450 m'), 0.45);
    expect(parseRouteDistanceKm(''), isNull);
  });
}
