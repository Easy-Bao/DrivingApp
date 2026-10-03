import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  group('typed ride values', () {
    test('validate and normalize extension-type identifiers', () {
      const rideId = RideId(' ride-42 ');
      const driverId = DriverId('driver-7');

      expect(rideId.isValid, isTrue);
      expect(rideId.normalized, 'ride-42');
      expect(driverId.normalized, 'driver-7');
      expect(RideId.tryParse('  '), isNull);
      expect(DriverId.tryParse(42), isNull);
    });

    test('keep distance and fare units type-safe', () {
      const distance = DistanceKm(1.25);
      const fare = FareCents(350);

      expect(distance.isShortHop, isTrue);
      expect(distance.meters, 1250);
      expect((distance + const DistanceKm(0.75)).value, 2);
      expect(fare.amount, 3.5);
      expect(fare.displayAmount, '₱3.50');
      expect((fare + const FareCents(50)).value, 400);
    });

    test('validate coordinate records without allocating wrapper objects', () {
      const valid = (8.056, 123.742);
      const invalid = (91.0, 123.742);

      expect(isValidRideCoordinates(valid), isTrue);
      expect(isValidRideCoordinates(invalid), isFalse);
    });
  });

  group('short-hop state presentation', () {
    const driver = RideDriver(
      id: DriverId('driver-7'),
      name: 'Alex',
      vehicleDescription: 'White sedan',
      rating: 4.9,
    );

    test('covers every state with an exhaustive message', () {
      const states = <ShortHopBookingState>[
        ShortHopIdle(),
        ShortHopDispatching(
          sessionId: BookingSessionId('session-1'),
          pickup: (8.056, 123.742),
          destination: (8.060, 123.746),
          routeDistance: DistanceKm(1.2),
          estimatedFare: FareCents(350),
        ),
        ShortHopDriverAssigned(
          rideId: RideId('ride-1'),
          driver: driver,
          driverLocation: (8.057, 123.743),
          pickup: (8.056, 123.742),
          destination: (8.060, 123.746),
          eta: Duration(minutes: 2),
        ),
        ShortHopInTransit(
          rideId: RideId('ride-1'),
          driver: driver,
          currentLocation: (8.058, 123.744),
          destination: (8.060, 123.746),
          eta: Duration(seconds: 30),
        ),
        ShortHopCompleted(
          rideId: RideId('ride-1'),
          fare: FareCents(350),
          distance: DistanceKm(1.2),
        ),
        ShortHopCancelled(
          rideId: RideId('ride-1'),
          reason: 'Passenger canceled.',
        ),
        ShortHopFailed(message: 'Dispatch unavailable.', code: 503),
      ];

      expect(
        states.map((state) => state.statusMessage),
        everyElement(isNotEmpty),
      );
      expect(states[2].driverLatitude, 8.057);
      expect(states[3].driverLatitude, 8.058);
      expect(states[0].driverLatitude, isNull);
    });
  });

  group('ride session access', () {
    test('promotes the private final token for an authorized action', () {
      String? receivedToken;

      final executed = RideSessionAccess('session-token')
          .executeAuthorizedAction((token, _) => receivedToken = token);

      expect(executed, isTrue);
      expect(receivedToken, 'session-token');
    });

    test('rejects missing or blank credentials', () {
      expect(RideSessionAccess(null).isAuthenticated, isFalse);
      expect(
        RideSessionAccess('  ').executeAuthorizedAction((_, _) {}),
        isFalse,
      );
    });
  });
}
