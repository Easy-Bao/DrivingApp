import 'package:core_domain/core_domain.dart';

class const BookingSessionRequest({
  required this.rideType,
  required this.pickupLatitude,
  required this.pickupLongitude,
  required this.pickupName,
  required this.dropoffLatitude,
  required this.dropoffLongitude,
  required this.dropoffName,
  required this.distanceKm,
  required this.durationMinutes,
  required this.customFareAmount,
  required this.passengerNote,
  this.targetDriverId,
}) {
  final String rideType;
  final double pickupLatitude;
  final double pickupLongitude;
  final String pickupName;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final String dropoffName;
  final double distanceKm;
  final double durationMinutes;
  final int customFareAmount;
  final String passengerNote;
  final int? targetDriverId;

  RideCoordinates get pickupCoordinates => (pickupLatitude, pickupLongitude);

  RideCoordinates get dropoffCoordinates => (dropoffLatitude, dropoffLongitude);

  DistanceKm get routeDistance => DistanceKm(distanceKm);

  FareCents get customFare => FareCents(customFareAmount);

  bool get isValid =>
      rideType.trim().isNotEmpty &&
      isValidRideCoordinates(pickupCoordinates) &&
      isValidRideCoordinates(dropoffCoordinates) &&
      routeDistance.value.isFinite &&
      routeDistance.value > 0 &&
      durationMinutes.isFinite &&
      durationMinutes > 0 &&
      customFare.isValid;
}
