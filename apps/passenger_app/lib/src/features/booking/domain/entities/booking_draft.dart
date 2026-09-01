import 'package:equatable/equatable.dart';
import 'package:maps/maps.dart';

class const BookingDraft({
  required this.destination,
  this.pickupAddress,
  this.tipAmount = 0,
  this.notes = '',
}) extends Equatable {
  final Place destination;
  final String? pickupAddress;
  final int tipAmount;
  final String notes;

  @override
  List<Object?> get props => [destination, pickupAddress, tipAmount, notes];
}
