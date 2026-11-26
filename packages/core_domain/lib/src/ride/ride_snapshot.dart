import 'package:core_domain/src/internal/json_parsing.dart';
import 'package:core_domain/src/ride/identifiers.dart';
import 'package:core_domain/src/ride/ride_status.dart';
import 'package:equatable/equatable.dart';

final class const RideSnapshot({
  required final String id,
  final String bookingReference = '',
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
  final DateTime? createdAt,
  final DateTime? arrivedAt,
  final DateTime? waitingUntil,
  final String? paymentStatus,
  final DateTime? cashReceivedAt,
  final String? cashOutcome,
  final int? cashReceivedAmount,
  final int? cashChangeAmount,
  final DateTime? completedAt,
  this.cashSettled = false,
}) extends Equatable {
  final bool cashSettled;

  RideSnapshot copyWith({
    String? id,
    String? bookingReference,
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
    DateTime? createdAt,
    DateTime? arrivedAt,
    DateTime? waitingUntil,
    String? paymentStatus,
    DateTime? cashReceivedAt,
    String? cashOutcome,
    int? cashReceivedAmount,
    int? cashChangeAmount,
    DateTime? completedAt,
    bool? cashSettled,
  }) => RideSnapshot(
    id: id ?? this.id,
    bookingReference: bookingReference ?? this.bookingReference,
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
    createdAt: createdAt ?? this.createdAt,
    arrivedAt: arrivedAt ?? this.arrivedAt,
    waitingUntil: waitingUntil ?? this.waitingUntil,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    cashReceivedAt: cashReceivedAt ?? this.cashReceivedAt,
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
      'arrived_at': rawArrivedAt,
      'waiting_until': rawWaitingUntil,
      'payment_status': rawPaymentStatus,
      'cash_received_at': rawCashReceivedAt,
      'cash_outcome': rawCashOutcome,
      'cash_received_amount': rawCashReceivedAmount,
      'cash_change_amount': rawCashChangeAmount,
      'completed_at': rawCompletedAt,
    } = _canonicalPayload(
      json,
    );

    return RideSnapshot(
      id: readTrimmedNonEmpty(rawId) ?? fallbackId ?? '',
      bookingReference: readStringValue(
        json['booking_reference'] ?? json['bookingReference'],
      ).trim(),
      status: readStringValue(rawStatus).trim().toLowerCase(),
      pickupName: readStringValue(rawPickupName, 'Pickup').trim(),
      dropoffName: readStringValue(rawDropoffName, 'Dropoff').trim(),
      passengerId: readTrimmedNonEmpty(rawPassengerId),
      passengerName: readTrimmedNonEmpty(rawPassengerName),
      driverId: readTrimmedNonEmpty(rawDriverId),
      driverName: readTrimmedNonEmpty(rawDriverName),
      vehicleType: readTrimmedNonEmpty(rawVehicleType),
      plateNumber: readTrimmedNonEmpty(rawPlateNumber),
      pickupLatitude: readNullableDouble(rawPickupLatitude),
      pickupLongitude: readNullableDouble(rawPickupLongitude),
      dropoffLatitude: readNullableDouble(rawDropoffLatitude),
      dropoffLongitude: readNullableDouble(rawDropoffLongitude),
      distanceKm: readNullableDouble(rawDistanceKm),
      durationMinutes: readNullableDouble(rawDurationMinutes),
      fareAmount: _fareAmount(rawFareAmount, rawFare),
      driverRating: readNullableDouble(rawDriverRating),
      createdAt: readNullableUtcDateTime(
        json['created_at'] ?? json['createdAt'],
      ),
      arrivedAt: readNullableUtcDateTime(rawArrivedAt),
      waitingUntil: readNullableUtcDateTime(rawWaitingUntil),
      paymentStatus: readTrimmedNonEmpty(rawPaymentStatus)?.toLowerCase(),
      cashReceivedAt: readNullableUtcDateTime(rawCashReceivedAt),
      cashOutcome: readTrimmedNonEmpty(rawCashOutcome)?.toLowerCase(),
      cashReceivedAmount: readNullableDouble(rawCashReceivedAmount)?.round(),
      cashChangeAmount: readNullableDouble(rawCashChangeAmount)?.round(),
      completedAt: readNullableUtcDateTime(rawCompletedAt),
      cashSettled: json['cash_settled'] == true || json['cashSettled'] == true,
    );
  }

  double? get farePesos => fareAmount == null ? null : fareAmount! / 100;

  RideId? get typedId => RideId.tryParse(id);

  PassengerId? get typedPassengerId => PassengerId.tryParse(passengerId);

  RideCoordinates? get pickupCoordinates =>
      _coordinatesOrNull(pickupLatitude, pickupLongitude);

  RideCoordinates? get dropoffCoordinates =>
      _coordinatesOrNull(dropoffLatitude, dropoffLongitude);

  DistanceKm? get routeDistance =>
      distanceKm == null ? null : DistanceKm(distanceKm!);

  FareCents? get typedFare =>
      fareAmount == null ? null : FareCents(fareAmount!);

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

  bool get isTerminal => RideStatus.fromString(status).isTerminal;

  /// Age is a recovery prompt, never evidence that a ride can be cancelled.
  bool needsRecoveryReview(DateTime now) {
    if (isTerminal) return false;
    final current = now.toUtc();
    if (status == 'arrived' && waitingUntil != null) {
      return !current.isBefore(waitingUntil!);
    }
    final started = createdAt;
    if (started == null || current.isBefore(started)) return false;
    if (status == 'accepted' || status == 'assigned' || status == 'arrived') {
      return current.difference(started) >= const Duration(minutes: 15);
    }
    if (status != 'in_transit') return false;
    final estimate = durationMinutes;
    final minutes = estimate != null && estimate.isFinite && estimate > 0
        ? estimate.ceil() + 30
        : 60;
    return current.difference(started) >=
        Duration(minutes: minutes < 60 ? 60 : minutes);
  }

  bool get hasCashSettlement =>
      cashReceivedAt != null ||
      (paymentStatus == 'paid' && cashOutcome == 'paid');

  @override
  List<Object?> get props => [
    id,
    bookingReference,
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
    createdAt,
    arrivedAt,
    waitingUntil,
    paymentStatus,
    cashReceivedAt,
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
  'arrived_at': json['arrived_at'] ?? json['arrivedAt'],
  'waiting_until': json['waiting_until'] ?? json['waitingUntil'],
  'payment_status': json['payment_status'] ?? json['paymentStatus'],
  'cash_received_at': json['cash_received_at'] ?? json['cashReceivedAt'],
  'cash_outcome': json['cash_outcome'] ?? json['cashOutcome'],
  'cash_received_amount':
      json['cash_received_amount'] ?? json['cashReceivedAmount'],
  'cash_change_amount': json['cash_change_amount'] ?? json['cashChangeAmount'],
  'completed_at': json['completed_at'] ?? json['completedAt'],
};

int? _fareAmount(Object? rawAmount, Object? rawPesos) {
  final amount = readNullableDouble(rawAmount);
  if (amount != null && amount.isFinite && amount >= 0) {
    return amount.round();
  }
  final pesos = readNullableDouble(rawPesos);
  if (pesos != null && pesos.isFinite && pesos >= 0) {
    return (pesos * 100).round();
  }
  return null;
}

RideCoordinates? _coordinatesOrNull(double? latitude, double? longitude) {
  if (latitude == null || longitude == null) return null;
  final coordinates = (latitude, longitude);
  return isValidRideCoordinates(coordinates) ? coordinates : null;
}
