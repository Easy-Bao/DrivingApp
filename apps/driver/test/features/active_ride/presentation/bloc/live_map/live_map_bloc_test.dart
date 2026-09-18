import 'package:driver/src/features/active_ride/presentation/bloc/live_map/live_map_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const originLat = 7.828;
  const originLng = 123.434;

  test('keeps the existing route while movement stays below the threshold', () {
    expect(
      hasExceededRouteDeviation(
        originLat: originLat,
        originLng: originLng,
        currentLat: originLat + 0.00044,
        currentLng: originLng,
      ),
      isFalse,
    );
  });

  test('requests a fresh route after movement exceeds fifty metres', () {
    expect(
      hasExceededRouteDeviation(
        originLat: originLat,
        originLng: originLng,
        currentLat: originLat + 0.00046,
        currentLng: originLng,
      ),
      isTrue,
    );
  });
}
