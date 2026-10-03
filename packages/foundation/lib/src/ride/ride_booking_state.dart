import 'package:equatable/equatable.dart';

import 'ride_identifiers.dart';

sealed class const ShortHopBookingState() extends Equatable {
  @override
  List<Object?> get props => const [];
}

final class const ShortHopIdle() extends ShortHopBookingState {}

final class const ShortHopDispatching({
  required final BookingSessionId sessionId,
  required final RideCoordinates pickup,
  required final RideCoordinates destination,
  required final DistanceKm routeDistance,
  required final FareCents estimatedFare,
}) extends ShortHopBookingState {
  @override
  List<Object?> get props => [
    sessionId,
    pickup,
    destination,
    routeDistance,
    estimatedFare,
  ];
}

final class const RideDriver({
  required final DriverId id,
  required final String name,
  required final String vehicleDescription,
  required final double rating,
}) extends Equatable {
  String get displayName => name.trim().isEmpty ? 'Driver' : name.trim();

  @override
  List<Object?> get props => [id, name, vehicleDescription, rating];
}

final class const ShortHopDriverAssigned({
  required final RideId rideId,
  required final RideDriver driver,
  required final RideCoordinates driverLocation,
  required final RideCoordinates pickup,
  required final RideCoordinates destination,
  required final Duration eta,
}) extends ShortHopBookingState {
  @override
  List<Object?> get props => [
    rideId,
    driver,
    driverLocation,
    pickup,
    destination,
    eta,
  ];
}

final class const ShortHopInTransit({
  required final RideId rideId,
  required final RideDriver driver,
  required final RideCoordinates currentLocation,
  required final RideCoordinates destination,
  required final Duration eta,
}) extends ShortHopBookingState {
  @override
  List<Object?> get props => [
    rideId,
    driver,
    currentLocation,
    destination,
    eta,
  ];
}

final class const ShortHopCompleted({
  required final RideId rideId,
  required final FareCents fare,
  required final DistanceKm distance,
}) extends ShortHopBookingState {
  @override
  List<Object?> get props => [rideId, fare, distance];
}

final class const ShortHopCancelled({
  required final RideId rideId,
  required final String reason,
}) extends ShortHopBookingState {
  @override
  List<Object?> get props => [rideId, reason];
}

final class const ShortHopFailed({
  required final String message,
  required final int code,
}) extends ShortHopBookingState {
  @override
  List<Object?> get props => [message, code];
}

extension ShortHopBookingStatePresentation on ShortHopBookingState {
  String get statusMessage => switch (this) {
    ShortHopIdle() => 'Ready to request a short hop.',
    ShortHopDispatching(:final routeDistance) when routeDistance.isShortHop =>
      'Connecting with nearby drivers...',
    ShortHopDispatching(:final routeDistance) =>
      'Connecting within ${routeDistance.label}...',
    ShortHopDriverAssigned(
      :final driver,
      driverLocation: (final latitude, final longitude),
    )
        when latitude != 0 && longitude != 0 =>
      '${driver.displayName} is on the way at '
          '(${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}).',
    ShortHopDriverAssigned(:final driver) =>
      '${driver.displayName} is on the way.',
    ShortHopInTransit(:final eta) when eta > Duration.zero =>
      'Arriving in ${_formatDuration(eta)}.',
    ShortHopInTransit() => 'Your short hop is in progress.',
    ShortHopCompleted(:final fare) => 'Trip complete • ${fare.displayAmount}.',
    ShortHopCancelled(:final reason) => 'Ride canceled: $reason',
    ShortHopFailed(:final message, :final code) =>
      'Ride failed [$code]: $message',
  };

  double? get driverLatitude => switch (this) {
    ShortHopDriverAssigned(driverLocation: (final latitude, _)) => latitude,
    ShortHopInTransit(currentLocation: (final latitude, _)) => latitude,
    _ => null,
  };
}

String _formatDuration(Duration duration) {
  if (duration.inMinutes > 0) return '${duration.inMinutes} min';
  return '${duration.inSeconds} sec';
}
