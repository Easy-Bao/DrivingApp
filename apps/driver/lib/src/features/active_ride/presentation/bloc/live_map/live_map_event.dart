part of 'live_map_bloc.dart';

sealed class LiveMapEvent {
  const LiveMapEvent();
}

final class InitializeMapEvent extends LiveMapEvent {
  const InitializeMapEvent({
    required this.controller,
    required this.defaultLatitude,
    required this.defaultLongitude,
    required this.routeColor,
  });

  final AppMapController controller;
  final double defaultLatitude;
  final double defaultLongitude;
  final Color routeColor;
}

final class UpdateLocationsAndDrawRouteEvent extends LiveMapEvent {
  const UpdateLocationsAndDrawRouteEvent({
    required this.driverLatitude,
    required this.driverLongitude,
    required this.passengerLatitude,
    required this.passengerLongitude,
    this.viewportPadding,
    this.routeTargetLatitude,
    this.routeTargetLongitude,
  });

  final double driverLatitude;
  final double driverLongitude;
  final double? passengerLatitude;
  final double? passengerLongitude;
  final EdgeInsets? viewportPadding;
  final double? routeTargetLatitude;
  final double? routeTargetLongitude;
}

final class ClearMapEvent extends LiveMapEvent {
  const ClearMapEvent();
}

final class DispatchTelemetryLocationEvent extends LiveMapEvent {
  const DispatchTelemetryLocationEvent({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}
