class BookingSessionRequest {
  const BookingSessionRequest({
    required this.rideType,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.pickupName,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.dropoffName,
    required this.distanceKm,
    required this.durationMinutes,
    required this.customFareCentavos,
    required this.passengerNote,
    this.targetDriverId,
  });

  final String rideType;
  final double pickupLatitude;
  final double pickupLongitude;
  final String pickupName;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final String dropoffName;
  final double distanceKm;
  final double durationMinutes;
  final int customFareCentavos;
  final String passengerNote;
  final int? targetDriverId;
}
