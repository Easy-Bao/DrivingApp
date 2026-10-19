part of 'booking_bloc.dart';

sealed class BookingState {
  const BookingState();
}

final class BookingInitial extends BookingState {
  const BookingInitial();
}

final class ActiveDriverSearch {
  const ActiveDriverSearch({
    required this.trip,
    required this.pickupLat,
    required this.pickupLng,
  });

  final BidSessionTrip trip;
  final double pickupLat;
  final double pickupLng;
}

final class FindingNearestDriver extends BookingState {
  const FindingNearestDriver({
    required this.trip,
    required this.pickupLat,
    required this.pickupLng,
  });

  final BidSessionTrip trip;
  final double pickupLat;
  final double pickupLng;
}

final class NearestDriverFound extends BookingState {
  const NearestDriverFound({
    required this.driver,
    this.nearbyDrivers = const [],
    this.totalTrips,
    this._reviewsDriverId,
    this.reviews = const [],
    this.isLoadingReviews = false,
    required this.trip,
    required this.pickupLat,
    required this.pickupLng,
  });

  final DriverModel driver;
  final List<DriverModel> nearbyDrivers;
  final int? totalTrips;
  final String? _reviewsDriverId;
  String get reviewsDriverId => _reviewsDriverId ?? driver.id;
  final List<DriverReview> reviews;
  final bool isLoadingReviews;
  final BidSessionTrip trip;
  final double pickupLat;
  final double pickupLng;

  NearestDriverFound copyWith({
    int? totalTrips,
    String? reviewsDriverId,
    List<DriverReview>? reviews,
    bool? isLoadingReviews,
  }) {
    return NearestDriverFound(
      driver: driver,
      nearbyDrivers: nearbyDrivers,
      totalTrips: totalTrips ?? this.totalTrips,
      reviewsDriverId: reviewsDriverId ?? this.reviewsDriverId,
      reviews: reviews ?? this.reviews,
      isLoadingReviews: isLoadingReviews ?? this.isLoadingReviews,
      trip: trip,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
    );
  }
}

final class BookingSearching extends BookingState {
  const BookingSearching({required this.isDirect, this.targetDriver});

  final bool isDirect;
  final DriverModel? targetDriver;
}

final class BookingOffersReceived extends BookingState {
  const BookingOffersReceived({
    required this.offers,
    required this.isDirect,
    this.targetDriver,
  });

  final List<BookingOffer> offers;
  final bool isDirect;
  final DriverModel? targetDriver;
}

final class DriverMatchResult {
  const DriverMatchResult({
    required this.driverId,
    required this.driverName,
    required this.vehicleType,
    required this.plateNumber,
    required this.proposedFare,
    this.driverRating,
  });

  final String driverId;
  final String driverName;
  final String vehicleType;
  final String plateNumber;
  final double proposedFare;
  final String? driverRating;
}

final class BookingDriverMatched extends BookingState {
  const BookingDriverMatched({required this.matchResult, this.rideId});

  final DriverMatchResult matchResult;
  final String? rideId;
}

final class BookingCanceled extends BookingState {
  const BookingCanceled();
}

final class BookingFailure extends BookingState {
  const BookingFailure(this.message, {this.isNoDriverFound = false});

  final String message;
  final bool isNoDriverFound;
}

extension BookingStateModernApi on BookingState {
  String get statusMessage => switch (this) {
    BookingInitial() => 'Ready to request a short hop.',
    FindingNearestDriver() => 'Locating nearest driver.',
    NearestDriverFound(:final driver) => '${driver.displayName} is nearby.',
    BookingSearching(:final isDirect, :final targetDriver) when isDirect =>
      'Waiting for ${targetDriver?.displayName ?? 'your driver'}.',
    BookingSearching() => 'Finding your driver.',
    BookingOffersReceived(:final offers, :final isDirect, :final targetDriver)
        when offers.isEmpty && isDirect =>
      'Waiting for ${targetDriver?.displayName ?? 'your driver'}.',
    BookingOffersReceived(:final offers) when offers.isEmpty =>
      'Finding your driver.',
    BookingOffersReceived(:final offers) =>
      '${offers.length} driver offers available.',
    BookingDriverMatched(:final matchResult) =>
      '${matchResult.driverName} is on the way.',
    BookingCanceled() => 'Booking canceled.',
    BookingFailure(:final message) => message,
  };

  RideCoordinates? get pickupCoordinates => switch (this) {
    FindingNearestDriver(:final pickupLat, :final pickupLng) => (
      pickupLat,
      pickupLng,
    ),
    NearestDriverFound(:final pickupLat, :final pickupLng) => (
      pickupLat,
      pickupLng,
    ),
    _ => null,
  };

  DriverId? get selectedDriverId => switch (this) {
    NearestDriverFound(:final driver) => driver.typedId,
    BookingOffersReceived(:final offers) when offers.length == 1 =>
      offers.first.typedDriverId,
    BookingDriverMatched(matchResult: DriverMatchResult(:final driverId)) =>
      DriverId.tryParse(driverId),
    _ => null,
  };
}
