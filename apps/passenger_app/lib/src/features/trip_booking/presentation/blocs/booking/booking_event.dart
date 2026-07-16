import 'package:passenger_services/passenger_services.dart';

/// Booking Event component defining application state or layout.
abstract class BookingEvent {
  const BookingEvent();
}

class LocateNearestDriverEvent extends BookingEvent {
  final double pickupLat;
  final double pickupLng;

  const LocateNearestDriverEvent({
    required this.pickupLat,
    required this.pickupLng,
  });
}

class StartDirectBookingEvent extends BookingEvent {
  final BidSessionTrip trip;
  final double pickupLat;
  final double pickupLng;
  final double distanceKm;
  final double durationMinutes;

  const StartDirectBookingEvent({
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
  final String driverName;
  final String vehicleType;
  final String plateNumber;
  final double proposedFare;

  const AcceptBidOfferEvent({
    required this.offerId,
    required this.driverName,
    required this.vehicleType,
    required this.plateNumber,
    required this.proposedFare,
  });
}

class CancelBookingEvent extends BookingEvent {
  const CancelBookingEvent();
}

class UpdateOffersEvent extends BookingEvent {
  final List<dynamic> offers;

  const UpdateOffersEvent(this.offers);
}

class DriverMatchedEvent extends BookingEvent {
  final DriverMatchResult matchResult;

  const DriverMatchedEvent(this.matchResult);
}
