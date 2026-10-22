import 'package:core_domain/core_domain.dart';
import 'package:foundation/foundation.dart';

class const BookingSessionRequest({
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
  this.idempotencyKey,
}) {
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
  final String? idempotencyKey;

  BookingSessionRequest copyWith({String? idempotencyKey}) =>
      BookingSessionRequest(
        pickupLatitude: pickupLatitude,
        pickupLongitude: pickupLongitude,
        pickupName: pickupName,
        dropoffLatitude: dropoffLatitude,
        dropoffLongitude: dropoffLongitude,
        dropoffName: dropoffName,
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        customFareAmount: customFareAmount,
        passengerNote: passengerNote,
        targetDriverId: targetDriverId,
        idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      );

  Map<String, dynamic> toJson() => {
    'pickup_latitude': pickupLatitude,
    'pickup_longitude': pickupLongitude,
    'pickup_name': pickupName,
    'dropoff_latitude': dropoffLatitude,
    'dropoff_longitude': dropoffLongitude,
    'dropoff_name': dropoffName,
    'distance_km': distanceKm,
    'duration_minutes': durationMinutes,
    'custom_fare': customFareAmount,
    'passenger_note': passengerNote,
    if (targetDriverId != null) 'target_driver_id': targetDriverId,
  };

  factory BookingSessionRequest.fromJson(Map<String, dynamic> json) =>
      BookingSessionRequest(
        pickupLatitude: SafeParse.toDouble(json['pickup_latitude']),
        pickupLongitude: SafeParse.toDouble(json['pickup_longitude']),
        pickupName: SafeParse.toStringValue(json['pickup_name']).trim(),
        dropoffLatitude: SafeParse.toDouble(json['dropoff_latitude']),
        dropoffLongitude: SafeParse.toDouble(json['dropoff_longitude']),
        dropoffName: SafeParse.toStringValue(json['dropoff_name']).trim(),
        distanceKm: SafeParse.toDouble(json['distance_km']),
        durationMinutes: SafeParse.toDouble(json['duration_minutes']),
        customFareAmount:
            SafeParse.toNullableDouble(json['custom_fare'])?.round() ?? 0,
        passengerNote: SafeParse.toStringValue(json['passenger_note']),
        targetDriverId: SafeParse.toNullableDouble(json['target_driver_id'])
            ?.round(),
      );

  RideCoordinates get pickupCoordinates => (pickupLatitude, pickupLongitude);

  RideCoordinates get dropoffCoordinates => (dropoffLatitude, dropoffLongitude);

  DistanceKm get routeDistance => DistanceKm(distanceKm);

  FareCents get customFare => FareCents(customFareAmount);

  bool get isValid =>
      isValidRideCoordinates(pickupCoordinates) &&
      isValidRideCoordinates(dropoffCoordinates) &&
      routeDistance.value.isFinite &&
      routeDistance.value > 0 &&
      durationMinutes.isFinite &&
      durationMinutes > 0 &&
      pickupName.trim().isNotEmpty &&
      dropoffName.trim().isNotEmpty &&
      customFare.isValid;
}
