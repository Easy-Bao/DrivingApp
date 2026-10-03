import 'package:foundation/foundation.dart';

final class const AcceptedBooking({
  required final String rideId,
  final int? fareAmount,
});

extension AcceptedBookingTypedValues on AcceptedBooking {
  RideId get typedRideId => RideId(rideId);

  FareCents? get typedFare =>
      fareAmount == null ? null : FareCents(fareAmount!);
}
