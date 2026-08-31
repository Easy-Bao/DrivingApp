import 'package:foundation/foundation.dart';

class BookingOffer {
  const BookingOffer({
    required this.offerId,
    required this.sessionId,
    required this.driverId,
    required this.driverName,
    required this.vehicleType,
    required this.plateNumber,
    required this.status,
    required this.proposedFareCentavos,
    this.driverRating,
  });

  static BookingOffer? tryParse(Map<String, dynamic> json) {
    final offerId = SafeParse.toStringValue(
      json['id'] ?? json['offer_id'],
    ).trim();
    final sessionId = SafeParse.toStringValue(json['session_id']).trim();
    final driverId = SafeParse.toStringValue(json['driver_id']).trim();
    final driverName = SafeParse.toStringValue(json['driver_name']).trim();
    final vehicleType = SafeParse.toStringValue(json['vehicle_type']).trim();
    final plateNumber = SafeParse.toStringValue(json['plate_number']).trim();
    final fare = SafeParse.toNullableDouble(json['proposed_fare_centavos']);
    if (offerId.isEmpty ||
        sessionId.isEmpty ||
        driverId.isEmpty ||
        fare == null ||
        fare <= 0) {
      return null;
    }
    return BookingOffer(
      offerId: offerId,
      sessionId: sessionId,
      driverId: driverId,
      driverName: driverName,
      vehicleType: vehicleType,
      plateNumber: plateNumber,
      status: SafeParse.toStringValue(json['status'], 'pending'),
      proposedFareCentavos: fare.round(),
      driverRating: SafeParse.toNullableDouble(json['driver_rating']),
    );
  }

  final String offerId;
  final String sessionId;
  final String driverId;
  final String driverName;
  final String vehicleType;
  final String plateNumber;
  final String status;
  final int proposedFareCentavos;
  final double? driverRating;

  double get proposedFare => proposedFareCentavos / 100;
  String get ratingLabel => driverRating?.toStringAsFixed(1) ?? '—';

  String get displayDriverName => driverName.isEmpty ? 'Driver' : driverName;

  String get displayVehicleType =>
      vehicleType.isEmpty ? 'Vehicle details unavailable' : vehicleType;

  String get displayPlateNumber => plateNumber.isEmpty ? '—' : plateNumber;

  String get vehicleSummary {
    final details = [
      vehicleType,
      plateNumber,
    ].where((value) => value.isNotEmpty).toList(growable: false);
    return details.isEmpty
        ? 'Vehicle details unavailable'
        : details.join(' • ');
  }
}
