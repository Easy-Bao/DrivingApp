import 'package:equatable/equatable.dart';
import 'package:foundation/foundation.dart';

class RideSnapshot extends Equatable {
  const RideSnapshot({
    required this.id,
    required this.status,
    required this.pickupName,
    required this.dropoffName,
    this.passengerId,
    this.passengerName,
    this.driverId,
    this.driverName,
    this.vehicleType,
    this.plateNumber,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropoffLatitude,
    this.dropoffLongitude,
    this.distanceKm,
    this.durationMinutes,
    this.fareCentavos,
  });

  factory RideSnapshot.fromJson(
    Map<String, dynamic> json, {
    String? fallbackId,
  }) {
    return RideSnapshot(
      id: _nullableString(json['id']) ?? fallbackId ?? '',
      status: SafeParse.toStringValue(json['status']).trim().toLowerCase(),
      pickupName: SafeParse.toStringValue(
        json['pickup_name'] ?? json['pickup'],
        'Pickup',
      ).trim(),
      dropoffName: SafeParse.toStringValue(
        json['dropoff_name'] ?? json['destination'],
        'Dropoff',
      ).trim(),
      passengerId: _nullableString(json['passenger_id'] ?? json['passengerId']),
      passengerName: _nullableString(
        json['passenger_name'] ?? json['passengerName'],
      ),
      driverId: _nullableString(json['driver_id'] ?? json['driverId']),
      driverName: _nullableString(json['driver_name'] ?? json['driverName']),
      vehicleType: _nullableString(json['vehicle_type'] ?? json['vehicleType']),
      plateNumber: _nullableString(json['plate_number'] ?? json['plateNumber']),
      pickupLatitude: SafeParse.toNullableDouble(
        json['pickup_latitude'] ?? json['pickupLat'],
      ),
      pickupLongitude: SafeParse.toNullableDouble(
        json['pickup_longitude'] ?? json['pickupLng'],
      ),
      dropoffLatitude: SafeParse.toNullableDouble(
        json['dropoff_latitude'] ??
            json['dropoffLatitude'] ??
            json['destination_latitude'],
      ),
      dropoffLongitude: SafeParse.toNullableDouble(
        json['dropoff_longitude'] ??
            json['dropoffLongitude'] ??
            json['destination_longitude'],
      ),
      distanceKm: SafeParse.toNullableDouble(
        json['distance_km'] ?? json['distance'],
      ),
      durationMinutes: SafeParse.toNullableDouble(
        json['duration_minutes'] ?? json['durationMinutes'],
      ),
      fareCentavos: _fareCentavos(json),
    );
  }

  final String id;
  final String status;
  final String pickupName;
  final String dropoffName;
  final String? passengerId;
  final String? passengerName;
  final String? driverId;
  final String? driverName;
  final String? vehicleType;
  final String? plateNumber;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? dropoffLatitude;
  final double? dropoffLongitude;
  final double? distanceKm;
  final double? durationMinutes;
  final int? fareCentavos;

  double? get farePesos => fareCentavos == null ? null : fareCentavos! / 100;

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
    fareCentavos,
  ];
}

int? _fareCentavos(Map<String, dynamic> json) {
  final centavos = SafeParse.toNullableDouble(json['fare_centavos']);
  if (centavos != null && centavos.isFinite && centavos >= 0) {
    return centavos.round();
  }
  final pesos = SafeParse.toNullableDouble(json['fare']);
  if (pesos != null && pesos.isFinite && pesos >= 0) {
    return (pesos * 100).round();
  }
  return null;
}

String? _nullableString(Object? value) {
  final normalized = SafeParse.toStringValue(value).trim();
  return normalized.isEmpty ? null : normalized;
}
