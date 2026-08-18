part of 'booking_bloc.dart';

abstract class BookingEvent {
  const BookingEvent();
}

class LocateNearestDriverEvent extends BookingEvent {
  final double pickupLat;
  final double pickupLng;
  final BidSessionTrip trip;

  const LocateNearestDriverEvent({
    required this.pickupLat,
    required this.pickupLng,
    required this.trip,
  });
}

class StartDirectBookingEvent extends BookingEvent {
  final DriverModel targetDriver;
  final BidSessionTrip trip;
  final double pickupLat;
  final double pickupLng;
  final double distanceKm;
  final double durationMinutes;

  const StartDirectBookingEvent({
    required this.targetDriver,
    required this.trip,
    required this.pickupLat,
    required this.pickupLng,
    required this.distanceKm,
    required this.durationMinutes,
  });
}

class StartOpenBookingEvent extends BookingEvent {
  final BidSessionTrip trip;
  final double pickupLat;
  final double pickupLng;
  final double distanceKm;
  final double durationMinutes;

  const StartOpenBookingEvent({
    required this.trip,
    required this.pickupLat,
    required this.pickupLng,
    required this.distanceKm,
    required this.durationMinutes,
  });
}

class AcceptBidOfferEvent extends BookingEvent {
  final String offerId;
  final String driverId;
  final String driverName;
  final String vehicleType;
  final String plateNumber;
  final double proposedFare;
  final String? driverRating;

  const AcceptBidOfferEvent({
    required this.offerId,
    required this.driverId,
    required this.driverName,
    required this.vehicleType,
    required this.plateNumber,
    required this.proposedFare,
    this.driverRating,
  });
}

class CancelBookingEvent extends BookingEvent {
  const CancelBookingEvent();
}

class ResetBookingEvent extends BookingEvent {
  const ResetBookingEvent();
}

class UpdateOffersEvent extends BookingEvent {
  final List<dynamic> offers;

  const UpdateOffersEvent(this.offers);
}

class DriverMatchedEvent extends BookingEvent {
  final DriverMatchResult matchResult;

  const DriverMatchedEvent(this.matchResult);
}
