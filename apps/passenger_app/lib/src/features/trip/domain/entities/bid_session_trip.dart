import 'package:equatable/equatable.dart';
import 'package:shared_core/shared_core.dart';

class BidSessionTrip extends Equatable {
  final String rideType;
  final double fare;
  final PlaceModel destination;
  final String distance;
  final String duration;
  final String? pickupAddress;
  final String passengerNote;

  const BidSessionTrip({
    required this.rideType,
    required this.fare,
    required this.destination,
    required this.distance,
    required this.duration,
    this.pickupAddress,
    this.passengerNote = '',
  });

  @override
  List<Object?> get props => [
    rideType,
    fare,
    destination,
    distance,
    duration,
    pickupAddress,
    passengerNote,
  ];
}
