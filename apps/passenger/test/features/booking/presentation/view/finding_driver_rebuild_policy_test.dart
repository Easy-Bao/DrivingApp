import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/booking/booking.dart';
import 'package:passenger/src/features/booking/domain/entities/bid_session_trip.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger/src/features/booking/presentation/view/finding_driver_page.dart';

const _destination = Place(
  id: 'destination-1',
  name: 'Pasadena Inn',
  fullAddress: 'Pasadena Inn',
  latitude: 7.83,
  longitude: 123.44,
);

const _trip = BidSessionTrip(
  rideType: 'solo',
  fare: 26,
  destination: _destination,
  distance: '1.2 km',
  duration: '5 min',
);

const _driver = DriverModel(
  id: 'driver-1',
  name: 'Demo Driver',
  vehicleType: 'Tricycle',
  plateNumber: 'ABC 2034',
  rating: 4.8,
  lat: 7.83,
  lng: 123.44,
  distanceKm: 0.4,
  etaMinutes: 3,
  score: 0.9,
);

void main() {
  test('rebuilds the discovery overlay only when visibility changes', () {
    const finding = FindingNearestDriver(
      trip: _trip,
      pickupLat: 7.82,
      pickupLng: 123.43,
    );
    const found = NearestDriverFound(
      driver: _driver,
      totalTrips: 12,
      reviews: [],
      isLoadingReviews: false,
      trip: _trip,
      pickupLat: 7.82,
      pickupLng: 123.43,
    );

    expect(shouldRebuildDriverDiscoveryOverlay(finding, finding), isFalse);
    expect(shouldRebuildDriverDiscoveryOverlay(finding, found), isTrue);
    expect(shouldRebuildDriverDiscoveryOverlay(found, found), isFalse);
    expect(shouldRebuildDriverDiscoveryOverlay(found, finding), isTrue);
  });
}
