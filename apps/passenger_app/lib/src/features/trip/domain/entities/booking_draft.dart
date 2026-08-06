import 'package:equatable/equatable.dart';
import 'package:shared_core/shared_core.dart';

class BookingDraft extends Equatable {
  final PlaceModel destination;
  final String? pickupAddress;

  const BookingDraft({required this.destination, this.pickupAddress});

  @override
  List<Object?> get props => [destination, pickupAddress];
}
