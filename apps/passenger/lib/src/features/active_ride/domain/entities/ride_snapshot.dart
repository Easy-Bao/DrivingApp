import 'package:equatable/equatable.dart';
import 'package:foundation/foundation.dart';

final class const RideSnapshot({
  required final String id,
  required final String status,
  required final String pickupName,
  required final String dropoffName,
  final String? passengerId,
  final String? passengerName,
  final String? driverId,
  final String? driverName,
  final String? vehicleType,
  final String? plateNumber,
  final double? pickupLatitude,
  final double? pickupLongitude,
  final double? dropoffLatitude,
  final double? dropoffLongitude,
  final double? distanceKm,
  final double? durationMinutes,
  final int? fareAmount,
}) extends Equatable {
  factory fromJson(Map<String, dynamic> json, {String? fallbackId}) {
    final {
      'id': rawId,
      'status': rawStatus,
      'pickup_name': rawPickupName,
      'dropoff_name': rawDropoffName,
      'passenger_id': rawPassengerId,
      'passenger_name': rawPassengerName,
      'driver_id': rawDriverId,
      'driver_name': rawDriverName,
      'vehicle_type': rawVehicleType,
      'plate_number': rawPlateNumber,
      'pickup_latitude': rawPickupLatitude,
      'pickup_longitude': rawPickupLongitude,
      'dropoff_latitude': rawDropoffLatitude,
      'dropoff_longitude': rawDropoffLongitude,
      'distance_km': rawDistanceKm,
      'duration_minutes': rawDurationMinutes,
      'fare_amount': rawFareAmount,
      'fare': rawFare,
    } = _canonicalPayload(
      json,
    );

    return RideSnapshot(
      id: _nullableString(rawId) ?? fallbackId ?? '',
      status: SafeParse.toStringValue(rawStatus).trim().toLowerCase(),
      pickupName: SafeParse.toStringValue(rawPickupName, 'Pickup').trim(),
      dropoffName: SafeParse.toStringValue(rawDropoffName, 'Dropoff').trim(),
      passengerId: _nullableString(rawPassengerId),
      passengerName: _nullableString(rawPassengerName),
      driverId: _nullableString(rawDriverId),
      driverName: _nullableString(rawDriverName),
      vehicleType: _nullableString(rawVehicleType),
      plateNumber: _nullableString(rawPlateNumber),
      pickupLatitude: SafeParse.toNullableDouble(rawPickupLatitude),
      pickupLongitude: SafeParse.toNullableDouble(rawPickupLongitude),
      dropoffLatitude: SafeParse.toNullableDouble(rawDropoffLatitude),
      dropoffLongitude: SafeParse.toNullableDouble(rawDropoffLongitude),
      distanceKm: SafeParse.toNullableDouble(rawDistanceKm),
      durationMinutes: SafeParse.toNullableDouble(rawDurationMinutes),
      fareAmount: _fareAmount(rawFareAmount, rawFare),
    );
  }

  double? get farePesos => fareAmount == null ? null : fareAmount! / 100;

  bool get isTerminal =>
      const {'completed', 'canceled', 'cancelled'}.contains(status);

  @override
  List<Object?> get props => [
    id,
    status,
    pickupName,
    dropoffName,
    passengerId,
    passengerName,
    driverId,
    driverName,
    vehicleType,
    plateNumber,
    pickupLatitude,
    pickupLongitude,
    dropoffLatitude,
    dropoffLongitude,
    distanceKm,
    durationMinutes,
    fareAmount,
  ];
}

Map<String, Object?> _canonicalPayload(Map<String, dynamic> json) => {
  'id': json['id'],
  'status': json['status'],
  'pickup_name': json['pickup_name'] ?? json['pickup'],
  'dropoff_name': json['dropoff_name'] ?? json['destination'],
  'passenger_id': json['passenger_id'] ?? json['passengerId'],
  'passenger_name': json['passenger_name'] ?? json['passengerName'],
  'driver_id': json['driver_id'] ?? json['driverId'],
  'driver_name': json['driver_name'] ?? json['driverName'],
  'vehicle_type': json['vehicle_type'] ?? json['vehicleType'],
  'plate_number': json['plate_number'] ?? json['plateNumber'],
  'pickup_latitude': json['pickup_latitude'] ?? json['pickupLat'],
  'pickup_longitude': json['pickup_longitude'] ?? json['pickupLng'],
  'dropoff_latitude':
      json['dropoff_latitude'] ??
      json['dropoffLatitude'] ??
      json['destination_latitude'],
  'dropoff_longitude':
      json['dropoff_longitude'] ??
      json['dropoffLongitude'] ??
      json['destination_longitude'],
  'distance_km': json['distance_km'] ?? json['distance'],
  'duration_minutes': json['duration_minutes'] ?? json['durationMinutes'],
  'fare_amount': json['fare_amount'],
  'fare': json['fare'],
};

int? _fareAmount(Object? rawAmount, Object? rawPesos) {
  final amount = SafeParse.toNullableDouble(rawAmount);
  if (amount != null && amount.isFinite && amount >= 0) {
    return amount.round();
  }
  final pesos = SafeParse.toNullableDouble(rawPesos);
  if (pesos != null && pesos.isFinite && pesos >= 0) {
    return (pesos * 100).round();
  }
  return null;
}

String? _nullableString(Object? value) {
  final normalized = SafeParse.toStringValue(value).trim();
  return normalized.isEmpty ? null : normalized;
}
