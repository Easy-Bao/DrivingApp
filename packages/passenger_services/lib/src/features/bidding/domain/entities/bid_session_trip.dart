import 'package:core_models/core_models.dart';

class BidSessionTrip {
  const BidSessionTrip({
    required this.rideType,
    required this.fare,
    required this.destination,
    required this.distance,
    required this.duration,
    this.pickupAddress,
  });

  final String rideType;
  final double fare;
  final PlaceModel destination;
  final String distance;
  final String duration;
  final String? pickupAddress;
}
