import 'package:foundation/foundation.dart';

final class const BidSessionSnapshot({
  required this.id,
  this.bookingReference = '',
  required this.status,
  required this.expiresAt,
  this.createdAt,

  this.pickupLatitude,
  this.pickupLongitude,
  this.pickupName,
  this.dropoffLatitude,
  this.dropoffLongitude,
  this.dropoffName,
  this.distanceKm,
  this.durationMinutes,
  this.offeredFareAmount,
  this.customFareAmount,
  this.passengerNote = '',
  this.targetDriverId,
  this.acceptedDriverId,
  this.rideId,
}) {
  final String id;
  final String bookingReference;
  final String status;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  final double? pickupLatitude;
  final double? pickupLongitude;
  final String? pickupName;
  final double? dropoffLatitude;
  final double? dropoffLongitude;
  final String? dropoffName;
  final double? distanceKm;
  final double? durationMinutes;
  final int? offeredFareAmount;
  final int? customFareAmount;
  final String passengerNote;
  final String? targetDriverId;
  final String? acceptedDriverId;
  final String? rideId;

  bool get isDeclined => status.trim().toLowerCase() == 'declined';
  bool get isExpired =>
      status.trim().toLowerCase() == 'expired' ||
      (expiresAt != null && expiresAt!.isBefore(DateTime.now()));
  bool get isOpen =>
      status.trim().toLowerCase() == 'open' &&
      (expiresAt == null || !expiresAt!.isBefore(DateTime.now()));
  bool get isAccepted => status.trim().toLowerCase() == 'accepted';
  bool get isCancelled =>
      const {'cancelled', 'canceled'}.contains(status.trim().toLowerCase());

  factory BidSessionSnapshot.fromJson(Map<String, dynamic> json) {
    final expiresAtValue = _value(json, 'expires_at', 'expiresAt');
    final createdAtValue = _value(json, 'created_at', 'createdAt');
    return BidSessionSnapshot(
      id: SafeParse.toStringValue(json['id']).trim(),
      bookingReference: SafeParse.toStringValue(
        json['booking_reference'] ?? json['bookingReference'],
      ).trim(),
      status: SafeParse.toStringValue(json['status']).trim().toLowerCase(),
      expiresAt: DateTime.tryParse(expiresAtValue)?.toUtc(),
      createdAt: DateTime.tryParse(createdAtValue)?.toUtc(),

      pickupLatitude: SafeParse.toNullableDouble(
        json['pickup_latitude'] ?? json['pickupLatitude'],
      ),
      pickupLongitude: SafeParse.toNullableDouble(
        json['pickup_longitude'] ?? json['pickupLongitude'],
      ),
      pickupName: _nullableString(json['pickup_name'] ?? json['pickupName']),
      dropoffLatitude: SafeParse.toNullableDouble(
        json['dropoff_latitude'] ?? json['dropoffLatitude'],
      ),
      dropoffLongitude: SafeParse.toNullableDouble(
        json['dropoff_longitude'] ?? json['dropoffLongitude'],
      ),
      dropoffName: _nullableString(json['dropoff_name'] ?? json['dropoffName']),
      distanceKm: SafeParse.toNullableDouble(
        json['distance_km'] ?? json['distanceKm'],
      ),
      durationMinutes: SafeParse.toNullableDouble(
        json['duration_minutes'] ?? json['durationMinutes'],
      ),
      offeredFareAmount: _integer(json['offered_fare'] ?? json['offeredFare']),
      customFareAmount: _integer(json['custom_fare'] ?? json['customFare']),
      passengerNote: SafeParse.toStringValue(
        json['passenger_note'] ?? json['passengerNote'],
      ).trim(),
      targetDriverId: _nullableString(
        json['target_driver_id'] ?? json['targetDriverId'],
      ),
      acceptedDriverId: _nullableString(
        json['accepted_driver_id'] ?? json['acceptedDriverId'],
      ),
      rideId: _nullableString(json['ride_id'] ?? json['rideId']),
    );
  }
}

String _value(Map<String, dynamic> json, String snakeCase, String camelCase) =>
    SafeParse.toStringValue(json[snakeCase] ?? json[camelCase]).trim();

String? _nullableString(Object? value) {
  final normalized = SafeParse.toStringValue(value).trim();
  return normalized.isEmpty ? null : normalized;
}

int? _integer(Object? value) => SafeParse.toNullableDouble(value)?.round();
