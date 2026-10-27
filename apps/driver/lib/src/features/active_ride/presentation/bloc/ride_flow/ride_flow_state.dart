import 'package:core_domain/core_domain.dart';
import 'package:equatable/equatable.dart';

sealed class const RideState() extends Equatable {
  @override
  List<Object?> get props => [];
}

final class const Idle() extends RideState;

final class const SearchingDriver({final String? passengerName})
    extends RideState {
  @override
  List<Object?> get props => [passengerName];
}

final class DriverEnRoute extends RideState {
  const DriverEnRoute({
    required this.passengerName,
    this.pickupLatitude,
    this.pickupLongitude,
    this.destinationLatitude,
    this.destinationLongitude,
    this.waitTimeSeconds,
  });

  final String passengerName;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final int? waitTimeSeconds;

  double? get pickupLat => pickupLatitude;
  double? get pickupLng => pickupLongitude;
  double? get destLat => destinationLatitude;
  double? get destLng => destinationLongitude;

  @override
  List<Object?> get props => [
    passengerName,
    pickupLatitude,
    pickupLongitude,
    destinationLatitude,
    destinationLongitude,
    waitTimeSeconds,
  ];
}

final class TripInProgress extends RideState {
  const TripInProgress({
    required this.passengerName,
    this.destinationLatitude,
    this.destinationLongitude,
    this.distanceKm,
    this.passengerLatitude,
    this.passengerLongitude,
  });

  final String passengerName;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final double? distanceKm;
  final double? passengerLatitude;
  final double? passengerLongitude;

  double? get destLat => destinationLatitude;
  double? get destLng => destinationLongitude;
  double? get passengerLat => passengerLatitude;
  double? get passengerLng => passengerLongitude;

  @override
  List<Object?> get props => [
    passengerName,
    destinationLatitude,
    destinationLongitude,
    distanceKm,
    passengerLatitude,
    passengerLongitude,
  ];
}

final class const TripCompleted({required final double fare})
    extends RideState {
  @override
  List<Object?> get props => [fare];
}

sealed class const RideFailed(final String message) extends RideState {
  @override
  List<Object?> get props => [message];
}

/// Compatibility name retained for existing Cubit and test signatures.
typedef RideFlowState = RideState;

/// Compatibility wrappers retain the established public state constructors.
final class const RideFlowInitial() extends Idle;

final class RideFlowNavigatingToPickup extends DriverEnRoute {
  const RideFlowNavigatingToPickup({
    required super.passengerName,
    super.pickupLatitude,
    super.pickupLongitude,
    super.destinationLatitude,
    super.destinationLongitude,
  });
}

final class RideFlowWaitingPassenger extends DriverEnRoute {
  const RideFlowWaitingPassenger({
    required super.passengerName,
    required super.waitTimeSeconds,
    super.pickupLatitude,
    super.pickupLongitude,
    super.destinationLatitude,
    super.destinationLongitude,
  });
}

final class RideFlowInTransit extends TripInProgress {
  const RideFlowInTransit({
    required super.passengerName,
    super.destinationLatitude,
    super.destinationLongitude,
    super.distanceKm,
    super.passengerLatitude,
    super.passengerLongitude,
  });
}

final class RideFlowError extends RideFailed {
  const RideFlowError(super.message);
}

final class RideFlowTerminal extends RideFailed {
  const RideFlowTerminal({
    required this.rideId,
    required this.status,
    required String message,
  }) : super(message);

  final String rideId;
  final String status;

  @override
  List<Object?> get props => [...super.props, rideId, status];
}

extension RideStatePresentation on RideState {
  String get statusMessage => switch (this) {
    Idle() => 'Ready for the next short hop.',
    SearchingDriver(:final passengerName) =>
      passengerName == null
          ? 'Hunting for nearby requests.'
          : 'Finding a ride for $passengerName.',
    DriverEnRoute(:final passengerName, :final waitTimeSeconds) =>
      waitTimeSeconds == null
          ? 'Heading to $passengerName.'
          : 'Waiting for $passengerName.',
    TripInProgress(:final passengerName, :final distanceKm) =>
      distanceKm == null
          ? 'Driving $passengerName.'
          : 'Driving $passengerName for ${DistanceKm(distanceKm).label}.',
    TripCompleted(:final fare) =>
      'Trip complete • ${FareCents((fare * 100).round()).displayAmount}.',
    RideFailed(:final message) => message,
  };

  bool get isWaitingAtPickup => switch (this) {
    Idle() ||
    SearchingDriver() ||
    TripInProgress() ||
    TripCompleted() ||
    RideFailed() => false,
    DriverEnRoute(:final waitTimeSeconds) => waitTimeSeconds != null,
  };

  String passengerNameOr(String fallback) => switch (this) {
    Idle() || SearchingDriver() || TripCompleted() || RideFailed() => fallback,
    DriverEnRoute(:final passengerName) ||
    TripInProgress(:final passengerName) => passengerName,
  };

  int waitTimeSecondsOr(int fallback) => switch (this) {
    Idle() ||
    SearchingDriver() ||
    TripInProgress() ||
    TripCompleted() ||
    RideFailed() => fallback,
    DriverEnRoute(:final waitTimeSeconds) => waitTimeSeconds ?? fallback,
  };

  double? get pickupLatitude => switch (this) {
    Idle() ||
    SearchingDriver() ||
    TripInProgress() ||
    TripCompleted() ||
    RideFailed() => null,
    DriverEnRoute(:final pickupLatitude) => pickupLatitude,
  };

  double? get pickupLongitude => switch (this) {
    Idle() ||
    SearchingDriver() ||
    TripInProgress() ||
    TripCompleted() ||
    RideFailed() => null,
    DriverEnRoute(:final pickupLongitude) => pickupLongitude,
  };

  double? get destinationLatitude => switch (this) {
    Idle() || SearchingDriver() || TripCompleted() || RideFailed() => null,
    DriverEnRoute(:final destinationLatitude) ||
    TripInProgress(:final destinationLatitude) => destinationLatitude,
  };

  double? get destinationLongitude => switch (this) {
    Idle() || SearchingDriver() || TripCompleted() || RideFailed() => null,
    DriverEnRoute(:final destinationLongitude) ||
    TripInProgress(:final destinationLongitude) => destinationLongitude,
  };

  RideCoordinates? get destinationCoordinates => switch (this) {
    DriverEnRoute(:final destinationLatitude, :final destinationLongitude)
        when destinationLatitude != null && destinationLongitude != null =>
      (destinationLatitude, destinationLongitude),
    TripInProgress(:final destinationLatitude, :final destinationLongitude)
        when destinationLatitude != null && destinationLongitude != null =>
      (destinationLatitude, destinationLongitude),
    _ => null,
  };

  DistanceKm? get routeDistance => switch (this) {
    TripInProgress(:final distanceKm) when distanceKm != null => DistanceKm(
      distanceKm,
    ),
    _ => null,
  };

  double? get passengerLatitude => switch (this) {
    Idle() ||
    SearchingDriver() ||
    DriverEnRoute() ||
    TripCompleted() ||
    RideFailed() => null,
    TripInProgress(:final passengerLatitude) => passengerLatitude,
  };

  double? get passengerLongitude => switch (this) {
    Idle() ||
    SearchingDriver() ||
    DriverEnRoute() ||
    TripCompleted() ||
    RideFailed() => null,
    TripInProgress(:final passengerLongitude) => passengerLongitude,
  };

  String? get failureMessage => switch (this) {
    Idle() ||
    SearchingDriver() ||
    DriverEnRoute() ||
    TripInProgress() ||
    TripCompleted() => null,
    RideFailed(:final message) => message,
  };
}
