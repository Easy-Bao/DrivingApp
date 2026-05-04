/// Represents a completed or canceled ride in the user's history.
class RideHistoryModel {
  final String id;
  final String pickup;
  final String destination;
  final double pickupLat;
  final double pickupLng;
  final double destLat;
  final double destLng;
  final String date;
  final String price;
  final String status; // "completed", "canceled", "progress"
  final String driverName;
  final String vehiclePlate;

  const RideHistoryModel({
    required this.id,
    required this.pickup,
    required this.destination,
    required this.pickupLat,
    required this.pickupLng,
    required this.destLat,
    required this.destLng,
    required this.date,
    required this.price,
    required this.status,
    this.driverName = '',
    this.vehiclePlate = '',
  });
}
