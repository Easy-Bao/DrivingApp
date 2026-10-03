import 'package:driver/src/features/active_ride/domain/entities/ride_snapshot.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('presents every driver ride state through an exhaustive message', () {
    const states = <RideState>[
      Idle(),
      SearchingDriver(),
      DriverEnRoute(passengerName: 'Alex'),
      TripInProgress(passengerName: 'Alex', distanceKm: 1.2),
      TripCompleted(fare: 3.5),
      RideFailed('Unable to update ride status.'),
    ];

    expect(
      states.map((state) => state.statusMessage),
      everyElement(isNotEmpty),
    );
    expect(states[3].routeDistance?.value, 1.2);
  });

  test('uses record coordinates for active destination data', () {
    const state = RideFlowInTransit(
      passengerName: 'Alex',
      destLat: 8.06,
      destLng: 123.746,
      distanceKm: 1.2,
    );

    expect(state.destinationCoordinates, (8.06, 123.746));
  });

  test('exposes typed snapshot identifiers and values', () {
    const snapshot = RideSnapshot(
      id: 'ride-42',
      status: 'in_transit',
      pickupName: 'Pickup',
      dropoffName: 'Dropoff',
      passengerId: 'passenger-7',
      pickupLatitude: 8.056,
      pickupLongitude: 123.742,
      dropoffLatitude: 8.06,
      dropoffLongitude: 123.746,
      distanceKm: 1.2,
      fareAmount: 350,
    );

    expect(snapshot.typedId?.normalized, 'ride-42');
    expect(snapshot.typedPassengerId?.normalized, 'passenger-7');
    expect(snapshot.pickupCoordinates, (8.056, 123.742));
    expect(snapshot.dropoffCoordinates, (8.06, 123.746));
    expect(snapshot.routeDistance?.isShortHop, isTrue);
    expect(snapshot.typedFare?.displayAmount, '₱3.50');
  });
}
