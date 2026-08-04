import 'package:passenger_app/src/features/booking/domain/entities/bid_session_trip.dart';
import 'package:shared_core/shared_core.dart';

abstract class BookingState {
  const BookingState();
}

class BookingInitial extends BookingState {}

class FindingNearestDriver extends BookingState {
  final BidSessionTrip trip;
  final double pickupLat;
  final double pickupLng;

  const FindingNearestDriver({
    required this.trip,
    required this.pickupLat,
    required this.pickupLng,
  });
}

class NearestDriverFound extends BookingState {
  final DriverModel driver;
  final List<DriverModel> nearbyDrivers;
  final int? totalTrips;
  final List<Map<String, dynamic>> reviews;
  final bool isLoadingReviews;
  final BidSessionTrip trip;
  final double pickupLat;
  final double pickupLng;

  const NearestDriverFound({
    required this.driver,
    this.nearbyDrivers = const [],
    required this.totalTrips,
    required this.reviews,
    required this.isLoadingReviews,
    required this.trip,
    required this.pickupLat,
    required this.pickupLng,
  });
}

class BookingSearching extends BookingState {
  final bool isDirect;
  final DriverModel? targetDriver;

  const BookingSearching({required this.isDirect, this.targetDriver});
}

class BookingOffersReceived extends BookingState {
  final List<dynamic> offers;
  final bool isDirect;
  final DriverModel? targetDriver;

  const BookingOffersReceived({
    required this.offers,
    required this.isDirect,
    this.targetDriver,
  });
}

class DriverMatchResult {
  final String driverId;
  final String driverName;
  final String vehicleType;
  final String plateNumber;
  final double proposedFare;

  const DriverMatchResult({
    required this.driverId,
    required this.driverName,
    required this.vehicleType,
    required this.plateNumber,
    required this.proposedFare,
  });
}

class BookingDriverMatched extends BookingState {
  final DriverMatchResult matchResult;

  final RideHistoryModel? createdRide;

  const BookingDriverMatched({required this.matchResult, this.createdRide});
}

class BookingCanceled extends BookingState {}

class BookingFailure extends BookingState {
  final String message;
  final bool isNoDriverFound;

  const BookingFailure(this.message, {this.isNoDriverFound = false});
}
