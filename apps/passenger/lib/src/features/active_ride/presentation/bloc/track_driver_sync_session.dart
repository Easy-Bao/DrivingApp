import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:foundation/foundation.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver_state.dart';

class TrackDriverSyncSession {
  TrackDriverSyncSession({
    required this.activeRideId,
    required this.fallbackDriverId,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.generation,
    required this.repository,
    required this.sessionService,
    required this.lifecycleCoordinator,
    required this.isCurrentOperation,
    required this.onEmit,
    required this.onClearTrackingState,
    required this.onStopBackgroundTelemetry,
  }) : _lastDriverLatitude = startLat,
       _lastDriverLongitude = startLng;

  final String activeRideId;
  final String fallbackDriverId;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final double destinationLat;
  final double destinationLng;
  final int generation;
  final TrackRepository repository;
  final SessionStore sessionService;
  final AppLifecycleCoordinator lifecycleCoordinator;
  final bool Function(int generation) isCurrentOperation;
  final void Function(TrackDriverState state) onEmit;
  final void Function(Future<void> Function() expectedResync)
  onClearTrackingState;
  final Future<void> Function() onStopBackgroundTelemetry;

  List<List<double>>? _routePoints;
  double _progress = 0.0;
  double _lastDriverLatitude;
  double _lastDriverLongitude;
  DateTime? _lastDriverLocationObservedAt;
  DateTime? _pickupRouteLastAttempt;
  DateTime? _destinationRouteLastAttempt;
  bool _trackingCompleted = false;
  bool _isSyncing = false;

  bool get isCompleted => _trackingCompleted;

  Future<void> sync() async {
    if (!isCurrentOperation(generation) ||
        !lifecycleCoordinator.isForeground ||
        _isSyncing ||
        _trackingCompleted ||
        activeRideId.isEmpty) {
      return;
    }

    _isSyncing = true;
    try {
      final result = await repository.getRideStatusResult(activeRideId);
      if (!isCurrentOperation(generation)) return;
      switch (result) {
        case Err(:final failure):
          dev.log('Error fetching status update: ${failure.message}');
          return;
        case Ok(value: final rideUpdate):
          if (!isCurrentOperation(generation)) return;
          if (rideUpdate.status == RideStatus.completed) {
            await _finishTerminal(
              TrackDriverCompleted(
                driverId: rideUpdate.driverId ?? fallbackDriverId,
                driverName: rideUpdate.driverName.isNotEmpty
                    ? rideUpdate.driverName
                    : 'Driver',
              ),
              logMessage:
                  'Unable to clear the completed passenger ride locally.',
            );
            return;
          }
          if (rideUpdate.status == RideStatus.cancelled) {
            await _finishTerminal(
              const TrackDriverCanceled(),
              logMessage:
                  'Unable to clear the canceled passenger ride locally.',
            );
            return;
          }

          await _syncActiveState(rideUpdate);
      }
    } catch (error, stackTrace) {
      dev.log(
        'Error synchronizing driver tracking',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _finishTerminal(
    TrackDriverState terminalState, {
    required String logMessage,
  }) async {
    _trackingCompleted = true;
    onClearTrackingState(sync);
    try {
      await sessionService.saveActiveRideId('');
    } catch (error, stackTrace) {
      dev.log(logMessage, error: error, stackTrace: stackTrace);
    }
    if (!isCurrentOperation(generation)) return;
    await onStopBackgroundTelemetry();
    if (!isCurrentOperation(generation)) return;
    onEmit(terminalState);
  }

  Future<void> _syncActiveState(RideUpdate rideUpdate) async {
    // A status transition is authoritative even when the location endpoint is
    // temporarily unavailable. Keep the last known coordinate so states such
    // as `arrived` still reach the UI.
    var resolvedDriverLat = _lastDriverLatitude;
    var resolvedDriverLng = _lastDriverLongitude;
    var locationFetched = false;

    final locationResult = await repository.fetchDriverLocationResult(
      activeRideId,
    );
    if (!isCurrentOperation(generation)) return;
    switch (locationResult) {
      case Err(:final failure):
        dev.log('Error fetching coordinate location: ${failure.message}');
      case Ok(value: final coordinate):
        resolvedDriverLat = coordinate.latitude;
        resolvedDriverLng = coordinate.longitude;
        _lastDriverLatitude = coordinate.latitude;
        _lastDriverLongitude = coordinate.longitude;
        _lastDriverLocationObservedAt = coordinate.observedAt;
        locationFetched = true;
    }

    final targetLatitude =
        rideUpdate.destinationLat ??
        (destinationLat == 0 ? null : destinationLat);
    final targetLongitude =
        rideUpdate.destinationLng ??
        (destinationLng == 0 ? null : destinationLng);
    final now = DateTime.now();

    if (locationFetched &&
        rideUpdate.status != RideStatus.inTransit &&
        _canRetryRoute(_pickupRouteLastAttempt, now)) {
      _pickupRouteLastAttempt = now;
      final candidate = await repository.getRoutePolyline(
        startLat: resolvedDriverLat,
        startLng: resolvedDriverLng,
        endLat: endLat,
        endLng: endLng,
      );
      if (!isCurrentOperation(generation)) return;
      if (_hasRouteGeometry(candidate)) {
        _routePoints = candidate;
      }
    }
    if (locationFetched &&
        rideUpdate.status == RideStatus.inTransit &&
        targetLatitude != null &&
        targetLongitude != null &&
        _canRetryRoute(_destinationRouteLastAttempt, now)) {
      _destinationRouteLastAttempt = now;
      final candidate = await repository.getRoutePolyline(
        startLat: resolvedDriverLat,
        startLng: resolvedDriverLng,
        endLat: targetLatitude,
        endLng: targetLongitude,
      );
      if (!isCurrentOperation(generation)) return;
      if (_hasRouteGeometry(candidate)) {
        _routePoints = candidate;
        _progress = 0;
      }
    }

    final eta = _etaLabelFor(rideUpdate.status);
    if (!isCurrentOperation(generation) || !lifecycleCoordinator.isForeground) {
      return;
    }

    if (!kReleaseMode) {
      final observedAt = _lastDriverLocationObservedAt;
      dev.Timeline.instantSync(
        'passenger.active_trip.displayed_location',
        arguments: {
          'location_age_ms': observedAt == null
              ? null
              : DateTime.now().difference(observedAt).inMilliseconds,
        },
      );
    }

    final trackingState = rideUpdate.status == RideStatus.inTransit
        ? TrackDriverTripInProgress(
            driverLat: resolvedDriverLat,
            driverLng: resolvedDriverLng,
            progress: _progress,
            eta: eta,
            routePoints: _routePoints,
            driverName: rideUpdate.driverName,
            vehiclePlate: rideUpdate.vehiclePlate,
            vehicleType: rideUpdate.vehicleType,
          )
        : TrackDriverInProgress(
            driverLat: resolvedDriverLat,
            driverLng: resolvedDriverLng,
            progress: _progress,
            eta: eta,
            routePoints: _routePoints,
            status: rideUpdate.status,
            driverName: rideUpdate.driverName,
            vehiclePlate: rideUpdate.vehiclePlate,
            vehicleType: rideUpdate.vehicleType,
          );
    onEmit(trackingState);
  }

  static bool _canRetryRoute(DateTime? lastAttempt, DateTime now) {
    return lastAttempt == null ||
        now.difference(lastAttempt) >= const Duration(seconds: 6);
  }

  static bool _hasRouteGeometry(List<List<double>>? points) {
    if (points == null || points.length < 2) return false;
    var validCount = 0;
    for (final point in points) {
      if (point.length >= 2 &&
          point[0].isFinite &&
          point[1].isFinite &&
          point[0] >= -180 &&
          point[0] <= 180 &&
          point[1] >= -90 &&
          point[1] <= 90) {
        if (++validCount >= 2) return true;
      }
    }
    return false;
  }

  static String _etaLabelFor(RideStatus status) => switch (status) {
    RideStatus.accepted => 'To Pickup',
    RideStatus.arrived => 'Arrived',
    RideStatus.inTransit => 'On Trip',
    _ => 'Calculating...',
  };
}
