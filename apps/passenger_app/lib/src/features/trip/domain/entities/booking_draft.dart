import 'package:equatable/equatable.dart';
import 'package:shared_core/shared_core.dart';

class BookingDraft extends Equatable {
  final PlaceModel destination;
  final String? pickupAddress;
  final int tipAmount;
  final String notes;

  const BookingDraft({
    required this.destination,
    this.pickupAddress,
    this.tipAmount = 0,
    this.notes = '',
  });

  @override
  List<Object?> get props => [destination, pickupAddress, tipAmount, notes];
}
