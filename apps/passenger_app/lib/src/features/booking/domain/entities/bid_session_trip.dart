import 'package:core_models/core_models.dart';
import 'package:equatable/equatable.dart';

class BidSessionTrip extends Equatable {
  final String rideType;
  final double fare;
  final PlaceModel destination;
  final String distance;
  final String duration;
  final String? pickupAddress;

  const BidSessionTrip({
    required this.rideType,
    required this.fare,
    required this.destination,
    required this.distance,
    required this.duration,
    this.pickupAddress,
  });

  @override
  List<Object?> get props => [
        rideType,
        fare,
        destination,
        distance,
        duration,
        pickupAddress,
      ];
}
