part of 'booking_bloc.dart';

abstract class const BookingEvent();

class const LocateNearestDriverEvent({
  required this.pickupLat,
  required this.pickupLng,
  required this.trip,
}) extends BookingEvent {
  final double pickupLat;
  final double pickupLng;
  final BidSessionTrip trip;
}

class const StartDirectBookingEvent({
  required this.targetDriver,
  required this.trip,
  required this.pickupLat,
  required this.pickupLng,
  required this.distanceKm,
  required this.durationMinutes,
}) extends BookingEvent {
  final DriverModel targetDriver;
  final BidSessionTrip trip;
  final double pickupLat;
  final double pickupLng;
  final double distanceKm;
  final double durationMinutes;
}

class const StartOpenBookingEvent({
  required this.trip,
  required this.pickupLat,
  required this.pickupLng,
  required this.distanceKm,
  required this.durationMinutes,
}) extends BookingEvent {
  final BidSessionTrip trip;
  final double pickupLat;
  final double pickupLng;
  final double distanceKm;
  final double durationMinutes;
}

class const AcceptBidOfferEvent({
  required this.offerId,
  required this.driverId,
  required this.driverName,
  required this.vehicleType,
  required this.plateNumber,
  required this.proposedFare,
  this.driverRating,
}) extends BookingEvent {
  final String offerId;
  final String driverId;
  final String driverName;
  final String vehicleType;
  final String plateNumber;
  final double proposedFare;
  final String? driverRating;
}

class const CancelBookingEvent() extends BookingEvent;

class const ResetBookingEvent() extends BookingEvent;

class const UpdateOffersEvent(this.offers) extends BookingEvent {
  final List<BookingOffer> offers;
}

class const DriverMatchedEvent(this.matchResult) extends BookingEvent {
  final DriverMatchResult matchResult;
}
