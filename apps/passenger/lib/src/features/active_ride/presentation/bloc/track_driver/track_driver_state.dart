import 'package:equatable/equatable.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';

sealed class const RideState() extends Equatable {
  @override
  List<Object?> get props => [];
}

final class const Idle() extends RideState;

final class const SearchingDriver({final String? driverName})
    extends RideState {
  @override
  List<Object?> get props => [driverName];
}

final class const DriverEnRoute({
  required final double driverLat,
  required final double driverLng,
  required final double progress,
  required final String eta,
  required final String driverName,
  required final String vehiclePlate,
  required final String vehicleType,
  final List<List<double>>? routePoints,
  final RideStatus status = RideStatus.accepted,
}) extends RideState {
  @override
  List<Object?> get props => [
    driverLat,
    driverLng,
    progress,
    eta,
    driverName,
    vehiclePlate,
    vehicleType,
    routePoints,
    status,
  ];
}

final class const TripInProgress({
  required final double driverLat,
  required final double driverLng,
  required final double progress,
  required final String eta,
  required final String driverName,
  required final String vehiclePlate,
  required final String vehicleType,
  final List<List<double>>? routePoints,
  final RideStatus status = RideStatus.inTransit,
}) extends RideState {
  @override
  List<Object?> get props => [
    driverLat,
    driverLng,
    progress,
    eta,
    driverName,
    vehiclePlate,
    vehicleType,
    routePoints,
    status,
  ];
}

final class const TripCompleted({
  required final String driverId,
  required final String driverName,
}) extends RideState {
  @override
  List<Object?> get props => [driverId, driverName];
}

final class const RideFailed(final String message) extends RideState {
  @override
  List<Object?> get props => [message];
}

/// Compatibility name retained for existing Cubit and test signatures.
typedef TrackDriverState = RideState;

final class const TrackDriverInitial() extends Idle;

/// Compatibility constructor retained for accepted and arrived snapshots.
final class const TrackDriverInProgress({
  required super.driverLat,
  required super.driverLng,
  required super.progress,
  required super.eta,
  required super.driverName,
  required super.vehiclePlate,
  required super.vehicleType,
  super.routePoints,
  super.status = RideStatus.accepted,
}) extends DriverEnRoute;

final class const TrackDriverTripInProgress({
  required super.driverLat,
  required super.driverLng,
  required super.progress,
  required super.eta,
  required super.driverName,
  required super.vehiclePlate,
  required super.vehicleType,
  super.routePoints,
  super.status = RideStatus.inTransit,
}) extends TripInProgress;

final class const TrackDriverCompleted({
  required super.driverId,
  required super.driverName,
}) extends TripCompleted;

final class TrackDriverCanceled extends RideFailed {
  const TrackDriverCanceled() : super('Ride canceled');
}

extension TrackDriverRideStatePresentation on RideState {
  bool get isTracking => switch (this) {
    DriverEnRoute() || TripInProgress() => true,
    Idle() || SearchingDriver() || TripCompleted() || RideFailed() => false,
  };

  bool get isInTransit => switch (this) {
    TripInProgress() => true,
    Idle() ||
    SearchingDriver() ||
    DriverEnRoute() ||
    TripCompleted() ||
    RideFailed() => false,
  };

  bool get hasArrived => switch (this) {
    DriverEnRoute(:final status) => status == RideStatus.arrived,
    Idle() ||
    SearchingDriver() ||
    TripInProgress() ||
    TripCompleted() ||
    RideFailed() => false,
  };

  double? get driverLatitude => switch (this) {
    DriverEnRoute(:final driverLat) ||
    TripInProgress(:final driverLat) => driverLat,
    Idle() || SearchingDriver() || TripCompleted() || RideFailed() => null,
  };

  double? get driverLongitude => switch (this) {
    DriverEnRoute(:final driverLng) ||
    TripInProgress(:final driverLng) => driverLng,
    Idle() || SearchingDriver() || TripCompleted() || RideFailed() => null,
  };

  double get trackingProgress => switch (this) {
    DriverEnRoute(:final progress) ||
    TripInProgress(:final progress) => progress,
    Idle() || SearchingDriver() || TripCompleted() || RideFailed() => 0,
  };

  String get trackingEta => switch (this) {
    DriverEnRoute(:final eta) || TripInProgress(:final eta) => eta,
    Idle() || SearchingDriver() || TripCompleted() || RideFailed() => '',
  };

  String get activeDriverName => switch (this) {
    DriverEnRoute(:final driverName) ||
    TripInProgress(:final driverName) => driverName,
    Idle() || SearchingDriver() || TripCompleted() || RideFailed() => '',
  };

  String get activeVehiclePlate => switch (this) {
    DriverEnRoute(:final vehiclePlate) ||
    TripInProgress(:final vehiclePlate) => vehiclePlate,
    Idle() || SearchingDriver() || TripCompleted() || RideFailed() => '',
  };

  String get activeVehicleType => switch (this) {
    DriverEnRoute(:final vehicleType) ||
    TripInProgress(:final vehicleType) => vehicleType,
    Idle() || SearchingDriver() || TripCompleted() || RideFailed() => '',
  };

  List<List<double>>? get activeRoutePoints => switch (this) {
    DriverEnRoute(:final routePoints) ||
    TripInProgress(:final routePoints) => routePoints,
    Idle() || SearchingDriver() || TripCompleted() || RideFailed() => null,
  };

  RideStatus get trackingStatus => switch (this) {
    DriverEnRoute(:final status) => status,
    TripInProgress(:final status) => status,
    Idle() || SearchingDriver() => RideStatus.unknown,
    TripCompleted() => RideStatus.completed,
    RideFailed() => RideStatus.cancelled,
  };

  String? get completedDriverId => switch (this) {
    TripCompleted(:final driverId) => driverId,
    Idle() ||
    SearchingDriver() ||
    DriverEnRoute() ||
    TripInProgress() ||
    RideFailed() => null,
  };

  String? get completedDriverName => switch (this) {
    TripCompleted(:final driverName) => driverName,
    Idle() ||
    SearchingDriver() ||
    DriverEnRoute() ||
    TripInProgress() ||
    RideFailed() => null,
  };
}
