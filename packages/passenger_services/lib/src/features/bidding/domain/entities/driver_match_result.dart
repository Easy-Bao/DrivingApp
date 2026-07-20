import 'package:passenger_services/src/features/bidding/domain/entities/bid_session_trip.dart';

class DriverMatchResult {
  const DriverMatchResult({
    required this.trip,
    required this.driverId,
    required this.driverName,
    required this.fare,
    this.driverRating,
    required this.vehicleType,
    required this.plateNumber,
  });

  final BidSessionTrip trip;
  final String driverId;
  final String driverName;
  final double fare;
  final String? driverRating;
  final String vehicleType;
  final String plateNumber;

  Map<String, dynamic> toNavigationExtra() {
    return {
      'rideType': trip.rideType,
      'fare': fare,
      'destination': trip.destination,
      'distance': trip.distance,
      'duration': trip.duration,
      'driverId': driverId,
      'driverName': driverName,
      'driverRating': driverRating,
      'vehicleType': vehicleType,
      'plateNumber': plateNumber,
      'pickupAddress': trip.pickupAddress ?? '',
    };
  }
}
