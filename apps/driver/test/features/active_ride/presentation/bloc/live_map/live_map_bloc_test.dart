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

  test('LiveMapState subclasses support value equality', () {
    expect(const LiveMapInitial(), equals(const LiveMapInitial()));
    expect(
      const LiveMapReady(7.828, 123.434),
      equals(const LiveMapReady(7.828, 123.434)),
    );
    expect(
      const LiveMapReady(7.828, 123.434),
      isNot(equals(const LiveMapReady(7.829, 123.434))),
    );
    expect(
      const LiveMapRouteUpdated(
        driverLatitude: 7.8,
        driverLongitude: 123.4,
        passengerLatitude: 7.9,
        passengerLongitude: 123.5,
      ),
      equals(
        const LiveMapRouteUpdated(
          driverLatitude: 7.8,
          driverLongitude: 123.4,
          passengerLatitude: 7.9,
          passengerLongitude: 123.5,
        ),
      ),
    );
    expect(
      const LiveMapRouteUpdated(
        driverLatitude: 7.8,
        driverLongitude: 123.4,
        passengerLatitude: 7.9,
        passengerLongitude: 123.5,
      ),
      isNot(
        equals(
          const LiveMapRouteUpdated(
            driverLatitude: 7.8,
            driverLongitude: 123.4,
            passengerLatitude: null,
            passengerLongitude: null,
          ),
        ),
      ),
    );
  });
}
