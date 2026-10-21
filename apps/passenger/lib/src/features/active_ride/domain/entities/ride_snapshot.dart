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
  final double? driverRating,
  final String? paymentStatus,
  final String? cashOutcome,
  final int? cashReceivedAmount,
  final int? cashChangeAmount,
  final DateTime? completedAt,
  this.cashSettled = false,
}) extends Equatable {
  final bool cashSettled;

  RideSnapshot copyWith({
    String? id,
    String? status,
    String? pickupName,
    String? dropoffName,
    String? passengerId,
    String? passengerName,
    String? driverId,
    String? driverName,
    String? vehicleType,
    String? plateNumber,
    double? pickupLatitude,
    double? pickupLongitude,
    double? dropoffLatitude,
    double? dropoffLongitude,
    double? distanceKm,
    double? durationMinutes,
    int? fareAmount,
    double? driverRating,
    String? paymentStatus,
    String? cashOutcome,
    int? cashReceivedAmount,
    int? cashChangeAmount,
    DateTime? completedAt,
    bool? cashSettled,
  }) => RideSnapshot(
    id: id ?? this.id,
    status: status ?? this.status,
    pickupName: pickupName ?? this.pickupName,
    dropoffName: dropoffName ?? this.dropoffName,
    passengerId: passengerId ?? this.passengerId,
    passengerName: passengerName ?? this.passengerName,
    driverId: driverId ?? this.driverId,
    driverName: driverName ?? this.driverName,
    vehicleType: vehicleType ?? this.vehicleType,
    plateNumber: plateNumber ?? this.plateNumber,
    pickupLatitude: pickupLatitude ?? this.pickupLatitude,
    pickupLongitude: pickupLongitude ?? this.pickupLongitude,
    dropoffLatitude: dropoffLatitude ?? this.dropoffLatitude,
    dropoffLongitude: dropoffLongitude ?? this.dropoffLongitude,
    distanceKm: distanceKm ?? this.distanceKm,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    fareAmount: fareAmount ?? this.fareAmount,
    driverRating: driverRating ?? this.driverRating,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    cashOutcome: cashOutcome ?? this.cashOutcome,
    cashReceivedAmount: cashReceivedAmount ?? this.cashReceivedAmount,
    cashChangeAmount: cashChangeAmount ?? this.cashChangeAmount,
    completedAt: completedAt ?? this.completedAt,
    cashSettled: cashSettled ?? this.cashSettled,
  );

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
      'driver_rating': rawDriverRating,
      'pickup_latitude': rawPickupLatitude,
      'pickup_longitude': rawPickupLongitude,
      'dropoff_latitude': rawDropoffLatitude,
      'dropoff_longitude': rawDropoffLongitude,
      'distance_km': rawDistanceKm,
      'duration_minutes': rawDurationMinutes,
      'fare_amount': rawFareAmount,
      'fare': rawFare,
      'payment_status': rawPaymentStatus,
      'cash_outcome': rawCashOutcome,
      'cash_received_amount': rawCashReceivedAmount,
      'cash_change_amount': rawCashChangeAmount,
      'completed_at': rawCompletedAt,
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
      driverRating: SafeParse.toNullableDouble(rawDriverRating),
      paymentStatus: _nullableString(rawPaymentStatus)?.toLowerCase(),
      cashOutcome: _nullableString(rawCashOutcome)?.toLowerCase(),
      cashReceivedAmount: SafeParse.toNullableDouble(rawCashReceivedAmount)
          ?.round(),
      cashChangeAmount: SafeParse.toNullableDouble(rawCashChangeAmount)
          ?.round(),
      completedAt: _nullableDateTime(rawCompletedAt),
      cashSettled: json['cash_settled'] == true || json['cashSettled'] == true,
    );
  }

  double? get farePesos => fareAmount == null ? null : fareAmount! / 100;

  String? get displayDriverRating {
    final rating = driverRating;
    if (rating == null || rating <= 0) return null;
    return rating.toStringAsFixed(1);
  }

  String get displayDriverName {
    final value = driverName?.trim() ?? '';
    return value.isEmpty ? 'Driver' : value;
  }

  String get displayVehicleSummary {
    final details = [
      vehicleType?.trim() ?? '',
      plateNumber?.trim() ?? '',
    ].where((value) => value.isNotEmpty).toList();
    return details.isEmpty
        ? 'Vehicle details unavailable'
        : details.join(' • ');
  }

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
    driverRating,
    paymentStatus,
    cashOutcome,
    cashReceivedAmount,
    cashChangeAmount,
    completedAt,
    cashSettled,
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
  'driver_rating': json['driver_rating'] ?? json['driverRating'],
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
  'payment_status': json['payment_status'] ?? json['paymentStatus'],
  'cash_outcome': json['cash_outcome'] ?? json['cashOutcome'],
  'cash_received_amount':
      json['cash_received_amount'] ?? json['cashReceivedAmount'],
  'cash_change_amount': json['cash_change_amount'] ?? json['cashChangeAmount'],
  'completed_at': json['completed_at'] ?? json['completedAt'],
  'cash_settled': json['cash_settled'] ?? json['cashSettled'],
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

DateTime? _nullableDateTime(Object? value) {
  final normalized = SafeParse.toStringValue(value).trim();
  return normalized.isEmpty ? null : DateTime.tryParse(normalized)?.toUtc();
}
