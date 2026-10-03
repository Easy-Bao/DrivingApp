import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/booking/domain/entities/bid_session_trip.dart';
import 'package:passenger/src/features/booking/domain/entities/driver_model.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking/booking_bloc.dart';

void main() {
  const trip = BidSessionTrip(
    rideType: 'Short Hop',
    fare: 350,
    destination: Place(
      id: 'destination',
      name: 'Library',
      fullAddress: 'Campus Library',
      latitude: 8.06,
      longitude: 123.746,
    ),
    distance: '1.2 km',
    duration: '4 min',
  );

  const driver = DriverModel(
    id: 'driver-7',
    name: 'Alex',
    vehicleType: 'Sedan',
    plateNumber: 'ABC 123',
    rating: 4.9,
    lat: 8.057,
    lng: 123.743,
    distanceKm: 0.4,
    etaMinutes: 2,
    score: 98,
  );

  test('uses exhaustive status messaging and coordinate records', () {
    const state = FindingNearestDriver(
      trip: trip,
      pickupLat: 8.056,
      pickupLng: 123.742,
    );

    expect(state.statusMessage, 'Locating nearest driver.');
    expect(state.pickupCoordinates, (8.056, 123.742));
  });

  test('exposes typed driver identity without changing the public model', () {
    const state = NearestDriverFound(
      driver: driver,
      totalTrips: 42,
      reviews: [],
      isLoadingReviews: false,
      trip: trip,
      pickupLat: 8.056,
      pickupLng: 123.742,
    );

    expect(state.statusMessage, 'Alex is nearby.');
    expect(state.selectedDriverId?.normalized, 'driver-7');
  });

  test('uses the direct target in searching and matched states', () {
    const searching = BookingSearching(isDirect: true, targetDriver: driver);
    const matched = BookingDriverMatched(
      matchResult: DriverMatchResult(
        driverId: 'driver-7',
        driverName: 'Alex',
        vehicleType: 'Sedan',
        plateNumber: 'ABC 123',
        proposedFare: 350,
      ),
    );

    expect(searching.statusMessage, 'Waiting for Alex.');
    expect(matched.statusMessage, 'Alex is on the way.');
    expect(matched.selectedDriverId?.normalized, 'driver-7');
  });
}
