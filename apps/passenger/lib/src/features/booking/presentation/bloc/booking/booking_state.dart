part of 'booking_bloc.dart';

sealed class const BookingState();

final class const BookingInitial() extends BookingState {}

final class const ActiveDriverSearch({
  required this.trip,
  required this.pickupLat,
  required this.pickupLng,
}) {
  final BidSessionTrip trip;
  final double pickupLat;
  final double pickupLng;
}

final class const FindingNearestDriver({
  required this.trip,
  required this.pickupLat,
  required this.pickupLng,
}) extends BookingState {
  final BidSessionTrip trip;
  final double pickupLat;
  final double pickupLng;
}

final class const NearestDriverFound({
  required this.driver,
  this.nearbyDrivers = const [],
  required this.totalTrips,
  required this.reviews,
  required this.isLoadingReviews,
  required this.trip,
  required this.pickupLat,
  required this.pickupLng,
}) extends BookingState {
  final DriverModel driver;
  final List<DriverModel> nearbyDrivers;
  final int? totalTrips;
  final List<Map<String, dynamic>> reviews;
  final bool isLoadingReviews;
  final BidSessionTrip trip;
  final double pickupLat;
  final double pickupLng;
}

final class const BookingSearching({required this.isDirect, this.targetDriver})
    extends BookingState {
  final bool isDirect;
  final DriverModel? targetDriver;
}

final class const BookingOffersReceived({
  required this.offers,
  required this.isDirect,
  this.targetDriver,
}) extends BookingState {
  final List<BookingOffer> offers;
  final bool isDirect;
  final DriverModel? targetDriver;
}

final class const DriverMatchResult({
  required this.driverId,
  required this.driverName,
  required this.vehicleType,
  required this.plateNumber,
  required this.proposedFare,
  this.driverRating,
}) {
  final String driverId;
  final String driverName;
  final String vehicleType;
  final String plateNumber;
  final double proposedFare;
  final String? driverRating;
}

final class const BookingDriverMatched({
  required this.matchResult,
  this.createdRide,
}) extends BookingState {
  final DriverMatchResult matchResult;

  final RideHistory? createdRide;
}

final class const BookingCanceled() extends BookingState {}

final class const BookingFailure(this.message, {this.isNoDriverFound = false})
    extends BookingState {
  final String message;
  final bool isNoDriverFound;
}
