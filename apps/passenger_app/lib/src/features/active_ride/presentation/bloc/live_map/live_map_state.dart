part of 'live_map_bloc.dart';

sealed class LiveMapState {
  const LiveMapState();
}

final class LiveMapInitial() extends LiveMapState;

final class const LiveMapReady(final double currentLat, final double currentLng)
    extends LiveMapState;

final class const LiveMapRouteDrawn({
  required final double riderLat,
  required final double riderLng,
  required final double driverLat,
  required final double driverLng,
}) extends LiveMapState;
