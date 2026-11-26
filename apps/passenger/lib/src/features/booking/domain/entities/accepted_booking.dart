import 'package:core_domain/core_domain.dart';
import 'package:equatable/equatable.dart';

final class const AcceptedBooking({required this.rideId, this.fareAmount})
    extends Equatable {
  final String rideId;
  final int? fareAmount;

  @override
  List<Object?> get props => [rideId, fareAmount];
}

extension AcceptedBookingTypedValues on AcceptedBooking {
  RideId get typedRideId => RideId(rideId);

  FareCents? get typedFare {
    final amount = fareAmount;
    return amount == null ? null : FareCents(amount);
  }
}
