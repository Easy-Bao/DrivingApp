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

final class const DriverEnRoute({
  required final String passengerName,
  final double? pickupLat,
  final double? pickupLng,
  final double? destLat,
  final double? destLng,
  final int? waitTimeSeconds,
}) extends RideState {
  @override
  List<Object?> get props => [
    passengerName,
    pickupLat,
    pickupLng,
    destLat,
    destLng,
    waitTimeSeconds,
  ];
}

final class const TripInProgress({
  required final String passengerName,
  final double? destLat,
  final double? destLng,
  final double? distanceKm,
  final double? passengerLat,
  final double? passengerLng,
}) extends RideState {
  @override
  List<Object?> get props => [
    passengerName,
    destLat,
    destLng,
    distanceKm,
    passengerLat,
    passengerLng,
  ];
}

final class const TripCompleted({required final double fare})
    extends RideState {
  @override
  List<Object?> get props => [fare];
}

final class const RideFailed(final String message) extends RideState {
  @override
  List<Object?> get props => [message];
}

/// Compatibility name retained for existing Cubit and test signatures.
typedef RideFlowState = RideState;

/// Compatibility wrappers retain the established public state constructors.
final class const RideFlowInitial() extends Idle;

final class const RideFlowNavigatingToPickup({
  required super.passengerName,
  super.pickupLat,
  super.pickupLng,
  super.destLat,
  super.destLng,
}) extends DriverEnRoute;

final class const RideFlowWaitingPassenger({
  required super.passengerName,
  required super.waitTimeSeconds,
  super.pickupLat,
  super.pickupLng,
  super.destLat,
  super.destLng,
}) extends DriverEnRoute;

final class const RideFlowInTransit({
  required super.passengerName,
  super.destLat,
  super.destLng,
  super.distanceKm,
  super.passengerLat,
  super.passengerLng,
}) extends TripInProgress;

final class RideFlowComplete extends TripCompleted {
  const RideFlowComplete({required super.fare});
}

final class RideFlowError extends RideFailed {
  const RideFlowError(super.message);
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
    DriverEnRoute(:final pickupLat) => pickupLat,
  };

  double? get pickupLongitude => switch (this) {
    Idle() ||
    SearchingDriver() ||
    TripInProgress() ||
    TripCompleted() ||
    RideFailed() => null,
    DriverEnRoute(:final pickupLng) => pickupLng,
  };

  double? get destinationLatitude => switch (this) {
    Idle() || SearchingDriver() || TripCompleted() || RideFailed() => null,
    DriverEnRoute(:final destLat) || TripInProgress(:final destLat) => destLat,
  };

  double? get destinationLongitude => switch (this) {
    Idle() || SearchingDriver() || TripCompleted() || RideFailed() => null,
    DriverEnRoute(:final destLng) || TripInProgress(:final destLng) => destLng,
  };

  RideCoordinates? get destinationCoordinates => switch (this) {
    DriverEnRoute(:final destLat, :final destLng)
        when destLat != null && destLng != null =>
      (destLat, destLng),
    TripInProgress(:final destLat, :final destLng)
        when destLat != null && destLng != null =>
      (destLat, destLng),
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
    TripInProgress(:final passengerLat) => passengerLat,
  };

  double? get passengerLongitude => switch (this) {
    Idle() ||
    SearchingDriver() ||
    DriverEnRoute() ||
    TripCompleted() ||
    RideFailed() => null,
    TripInProgress(:final passengerLng) => passengerLng,
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
