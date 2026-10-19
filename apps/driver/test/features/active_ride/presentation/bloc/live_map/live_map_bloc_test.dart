import 'package:driver/src/features/active_ride/presentation/bloc/live_map/live_map_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const originLatitude = 7.828;
  const originLongitude = 123.434;

  test('keeps the existing route while movement stays below the threshold', () {
    expect(
      hasExceededRouteDeviation(
        originLatitude: originLatitude,
        originLongitude: originLongitude,
        currentLatitude: originLatitude + 0.00044,
        currentLongitude: originLongitude,
      ),
      isFalse,
    );
  });

  test('requests a fresh route after movement exceeds fifty metres', () {
    expect(
      hasExceededRouteDeviation(
        originLatitude: originLatitude,
        originLongitude: originLongitude,
        currentLatitude: originLatitude + 0.00046,
        currentLongitude: originLongitude,
      ),
      isTrue,
    );
  });
}
