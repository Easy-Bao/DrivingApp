part of 'booking_bloc.dart';

sealed class const BookingEvent();

final class const LocateNearestDriverEvent({
  required this.pickupLat,
  required this.pickupLng,
  required this.trip,
}) extends BookingEvent {
  final double pickupLat;
  final double pickupLng;
  final BidSessionTrip trip;
}

final class const LoadDriverReviewsEvent({required this.driverId})
    extends BookingEvent {
  final String driverId;
}

final class const StartDirectBookingEvent({
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

final class const StartOpenBookingEvent({
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

final class const AcceptBidOfferEvent({
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

final class const CancelBookingEvent() extends BookingEvent;

final class const ResetBookingEvent() extends BookingEvent;

final class const RestoreActiveBookingEvent() extends BookingEvent;

final class const RefreshBookingSessionEvent() extends BookingEvent;

final class const UpdateOffersEvent(
  this.offers, {
  this.session,
  this.refreshError,
}) extends BookingEvent {
  final List<BookingOffer> offers;
  final BidSessionSnapshot? session;
  final String? refreshError;
}

final class const DriverMatchedEvent(this.matchResult) extends BookingEvent {
  final DriverMatchResult matchResult;
}
