import 'package:equatable/equatable.dart';
import 'package:maps/maps.dart';

class const BidSessionTrip({
  required this.rideType,
  required this.fare,
  required this.destination,
  required this.distance,
  required this.duration,
  this.pickupAddress,
  this.passengerNote = '',
}) extends Equatable {
  final String rideType;
  final double fare;
  final Place destination;
  final String distance;
  final String duration;
  final String? pickupAddress;
  final String passengerNote;

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
