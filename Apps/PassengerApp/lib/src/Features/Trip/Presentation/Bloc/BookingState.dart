import 'package:core_models/CoreModels.dart';


abstract class BookingState {
  const BookingState();
}

class BookingInitial extends BookingState {}

class FindingNearestDriver extends BookingState {}

class NearestDriverFound extends BookingState {
  final DriverModel driver;
  final List<DriverModel> nearbyDrivers;
  final int totalTrips;
  final List<Map<String, dynamic>> reviews;
  final bool isLoadingReviews;

  const NearestDriverFound({
    required this.driver,
    this.nearbyDrivers = const [],
    required this.totalTrips,
    required this.reviews,
    required this.isLoadingReviews,
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

  const BookingFailure(this.message);
}
