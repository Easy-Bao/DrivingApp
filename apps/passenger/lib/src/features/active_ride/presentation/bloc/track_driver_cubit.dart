import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/core/telemetry/background_telemetry.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver_state.dart';

class TrackDriverCubit extends Cubit<TrackDriverState> {
  TrackDriverCubit({
    required this.repository,
    required this.sessionService,
    required this.lifecycleCoordinator,
    this.backgroundTelemetryService,
  }) : super(const TrackDriverInitial());

  final TrackRepository repository;
  final PassengerSessionStore sessionService;
  final PassengerBackgroundTelemetry? backgroundTelemetryService;
  final AppLifecycleCoordinator lifecycleCoordinator;

  TrackRepository get _repository => repository;
  PassengerSessionStore get _sessionService => sessionService;
  PassengerBackgroundTelemetry? get _backgroundTelemetryService =>
      backgroundTelemetryService;
  AppLifecycleCoordinator get _lifecycleCoordinator => lifecycleCoordinator;
  AppLifecyclePeriodicTask? _trackingTask;
  Future<void> Function()? _activeTripResync;
  bool _isSyncing = false;
  int? _syncGeneration;
  int _trackingGeneration = 0;
  String? _activeRideId;
  DateTime? _lastPassengerLocationPublishedAt;
  bool _isCancellingTrip = false;
  bool _isEmergencyStopping = false;

  Future<void> resetTracking() async {
    if (isClosed) return;
    ++_trackingGeneration;
    _activeRideId = null;
    _lastPassengerLocationPublishedAt = null;
    unawaited(_trackingTask?.dispose());
    _trackingTask = null;
    _activeTripResync = null;
    await _stopBackgroundTelemetry();
    if (!isClosed) emit(const TrackDriverInitial());
  }

  Future<void> startTracking({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required String rideId,
    required String driverId,
    required String driverName,
    required String vehiclePlate,
    required String vehicleType,
    double destinationLat = 0,
    double destinationLng = 0,
  }) async {
    if (isClosed) return;
    final trackingGeneration = ++_trackingGeneration;
    _activeRideId = rideId.isEmpty ? null : rideId;
    _lastPassengerLocationPublishedAt = null;
    unawaited(_trackingTask?.dispose());
    _trackingTask = null;
    _activeTripResync = null;

    final session = _sessionService;
    late final String activeRideId;
    try {
      if (rideId.isNotEmpty) {
        await session.saveActiveRideId(rideId);
        if (!_isCurrentTrackingOperation(trackingGeneration)) return;
      }
      activeRideId = await session.readActiveRideId() ?? '';
    } catch (error) {
      if (_isCurrentTrackingOperation(trackingGeneration)) {
        _activeRideId = null;
        _lastPassengerLocationPublishedAt = null;
      }
      rethrow;
    }
    if (!_isCurrentTrackingOperation(trackingGeneration)) return;
    _activeRideId = activeRideId.isEmpty ? null : activeRideId;

    List<List<double>>? routePoints;

    double progress = 0.0;
    var lastDriverLatitude = startLat;
    var lastDriverLongitude = startLng;
    DateTime? lastDriverLocationObservedAt;
    DateTime? pickupRouteLastAttempt;
    DateTime? destinationRouteLastAttempt;
    var trackingCompleted = false;

    late final Future<void> Function() activeTripResync;

    Future<void> syncTracking() async {
      if (!_isCurrentTrackingOperation(trackingGeneration) ||
          !_lifecycleCoordinator.isForeground ||
          (_isSyncing && _syncGeneration == trackingGeneration) ||
          trackingCompleted ||
          activeRideId.isEmpty) {
        return;
      }

      _isSyncing = true;
      _syncGeneration = trackingGeneration;
      try {
        final result = await _repository.getRideStatusResult(activeRideId);
        if (!_isCurrentTrackingOperation(trackingGeneration)) return;
        await result.fold(
          (failure) async {
            dev.log('Error fetching status update: ${failure.message}');
          },
          (rideUpdate) async {
            if (!_isCurrentTrackingOperation(trackingGeneration)) return;
            if (rideUpdate.status == RideStatus.completed) {
              trackingCompleted = true;
              _activeRideId = null;
              _lastPassengerLocationPublishedAt = null;
              unawaited(_trackingTask?.dispose());
              _trackingTask = null;
              if (identical(_activeTripResync, activeTripResync)) {
                _activeTripResync = null;
              }
              emit(
                TrackDriverCompleted(
                  driverId: rideUpdate.driverId ?? driverId,
                  driverName: rideUpdate.driverName.isNotEmpty
                      ? rideUpdate.driverName
                      : 'Driver',
                ),
              );
              await session.saveActiveRideId('');
              if (!_isCurrentTrackingOperation(trackingGeneration)) return;
              await _stopBackgroundTelemetry();
              if (!_isCurrentTrackingOperation(trackingGeneration)) return;
              return;
            }
            if (rideUpdate.status == RideStatus.cancelled) {
              trackingCompleted = true;
              _activeRideId = null;
              _lastPassengerLocationPublishedAt = null;
              unawaited(_trackingTask?.dispose());
              _trackingTask = null;
              if (identical(_activeTripResync, activeTripResync)) {
                _activeTripResync = null;
              }
              await session.saveActiveRideId('');
              if (!_isCurrentTrackingOperation(trackingGeneration)) return;
              await _stopBackgroundTelemetry();
              if (!_isCurrentTrackingOperation(trackingGeneration)) return;
              emit(const TrackDriverCanceled());
              return;
            }

            double? driverLatitude;
            double? driverLongitude;
            DateTime? driverLocationObservedAt;
            bool locationFetched = false;

            final locationResult = await _repository.fetchDriverLocationResult(
              activeRideId,
            );
            if (!_isCurrentTrackingOperation(trackingGeneration)) return;
            locationResult.fold(
              (failure) {
                dev.log(
                  'Error fetching coordinate location: ${failure.message}',
                );
              },
              (coordinate) {
                driverLatitude = coordinate.latitude;
                driverLongitude = coordinate.longitude;
                driverLocationObservedAt = coordinate.observedAt;
                locationFetched = true;
              },
            );

            // A status transition is authoritative even when the location
            // endpoint is temporarily unavailable. Keep the last known
            // coordinate so states such as `arrived` still reach the UI.
            driverLatitude ??= lastDriverLatitude;
            driverLongitude ??= lastDriverLongitude;
            if (locationFetched) {
              lastDriverLatitude = driverLatitude!;
              lastDriverLongitude = driverLongitude!;
              lastDriverLocationObservedAt = driverLocationObservedAt;
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
                _canRetryRoute(pickupRouteLastAttempt, now)) {
              pickupRouteLastAttempt = now;
              final candidate = await _repository.getRoutePolyline(
                startLat: driverLatitude!,
                startLng: driverLongitude!,
                endLat: endLat,
                endLng: endLng,
              );
              if (!_isCurrentTrackingOperation(trackingGeneration)) return;
              if (_hasRouteGeometry(candidate)) {
                routePoints = candidate;
              }
            }
            if (locationFetched &&
                rideUpdate.status == RideStatus.inTransit &&
                targetLatitude != null &&
                targetLongitude != null &&
                _canRetryRoute(destinationRouteLastAttempt, now)) {
              destinationRouteLastAttempt = now;
              final candidate = await _repository.getRoutePolyline(
                startLat: driverLatitude!,
                startLng: driverLongitude!,
                endLat: targetLatitude,
                endLng: targetLongitude,
              );
              if (!_isCurrentTrackingOperation(trackingGeneration)) return;
              if (_hasRouteGeometry(candidate)) {
                routePoints = candidate;
                progress = 0;
              }
            }

            final eta = _getEtaLabel(rideUpdate.status);

            if (_isCurrentTrackingOperation(trackingGeneration) &&
                _lifecycleCoordinator.isForeground) {
              if (!kReleaseMode) {
                final observedAt = lastDriverLocationObservedAt;
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
                      driverLat: driverLatitude!,
                      driverLng: driverLongitude!,
                      progress: progress,
                      eta: eta,
                      routePoints: routePoints,
                      driverName: rideUpdate.driverName,
                      vehiclePlate: rideUpdate.vehiclePlate,
                      vehicleType: rideUpdate.vehicleType,
                    )
                  : TrackDriverInProgress(
                      driverLat: driverLatitude!,
                      driverLng: driverLongitude!,
                      progress: progress,
                      eta: eta,
                      routePoints: routePoints,
                      status: rideUpdate.status,
                      driverName: rideUpdate.driverName,
                      vehiclePlate: rideUpdate.vehiclePlate,
                      vehicleType: rideUpdate.vehicleType,
                    );
              emit(trackingState);
            }
          },
        );
      } catch (error, stackTrace) {
        dev.log(
          'Error synchronizing driver tracking',
          error: error,
          stackTrace: stackTrace,
        );
      } finally {
        if (_syncGeneration == trackingGeneration) {
          _isSyncing = false;
          _syncGeneration = null;
        }
      }
    }

    activeTripResync = syncTracking;
    _activeTripResync = activeTripResync;

    if (_lifecycleCoordinator.isForeground &&
        _isCurrentTrackingOperation(trackingGeneration)) {
      await activeTripResync();
    }
    if (!trackingCompleted && _isCurrentTrackingOperation(trackingGeneration)) {
      final task = AppLifecyclePeriodicTask(
        lifecycleCoordinator: _lifecycleCoordinator,
        interval: const Duration(seconds: 2),
        onTick: activeTripResync,
        runImmediatelyOnResume: true,
      );
      _trackingTask = task;
      task.start();
    }
  }

  Future<void> resyncActiveTrip() async {
    if (isClosed) return;
    final resync = _activeTripResync;
    if (resync == null) return;
    await resync();
  }

  Future<void> publishPassengerLocation({
    required String rideId,
    required double latitude,
    required double longitude,
  }) async {
    final activeRideId = _activeRideId;
    if (isClosed ||
        _isCancellingTrip ||
        _isEmergencyStopping ||
        activeRideId == null ||
        rideId != activeRideId) {
      return;
    }

    final now = DateTime.now();
    final lastPublishedAt = _lastPassengerLocationPublishedAt;
    if (lastPublishedAt != null &&
        now.difference(lastPublishedAt) < const Duration(seconds: 5)) {
      return;
    }
    _lastPassengerLocationPublishedAt = now;

    try {
      final result = await _repository.publishPassengerLocationResult(
        rideId: activeRideId,
        latitude: latitude,
        longitude: longitude,
      );
      result.fold(
        (failure) =>
            dev.log('Passenger telemetry update failed: ${failure.message}'),
        (_) {},
      );
    } catch (error, stackTrace) {
      dev.log(
        'Passenger telemetry update failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  bool _canRetryRoute(DateTime? lastAttempt, DateTime now) {
    return lastAttempt == null ||
        now.difference(lastAttempt) >= const Duration(seconds: 6);
  }

  bool _hasRouteGeometry(List<List<double>>? points) {
    return points != null &&
        points.where((point) {
              return point.length >= 2 &&
                  point[0].isFinite &&
                  point[1].isFinite &&
                  point[0] >= -180 &&
                  point[0] <= 180 &&
                  point[1] >= -90 &&
                  point[1] <= 90;
            }).length >=
            2;
  }

  Future<void> cancelTrip({
    String reason = 'passenger_changed_mind',
    String details = '',
  }) async {
    await cancelTripRequest(reason: reason, details: details);
  }

  /// Requests cancellation while keeping the active tracker alive until the
  /// server confirms the transition. A false result leaves the prior ride
  /// state and polling owner in place for UI rollback.
  Future<bool> cancelTripRequest({
    String reason = 'passenger_changed_mind',
    String details = '',
  }) async {
    if (isClosed || _isCancellingTrip) return false;
    ++_trackingGeneration;
    _isCancellingTrip = true;
    try {
      final rideId = await _sessionService.readActiveRideId() ?? '';
      if (rideId.isNotEmpty) {
        final result = await _repository.cancelRideResult(
          rideId: rideId,
          reason: reason,
          details: details,
        );
        final failure = result.fold<Failure?>((value) => value, (_) => null);
        if (failure != null) {
          dev.log('Unable to cancel passenger trip: ${failure.message}');
          return false;
        }
        try {
          await _sessionService.saveActiveRideId('');
        } catch (error, stackTrace) {
          dev.log(
            'Unable to clear the canceled passenger ride locally.',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }

      unawaited(_trackingTask?.dispose());
      _trackingTask = null;
      _activeTripResync = null;
      _activeRideId = null;
      _lastPassengerLocationPublishedAt = null;
      await _stopBackgroundTelemetry();
      if (!isClosed) emit(const TrackDriverCanceled());
      return true;
    } catch (error) {
      dev.log('Error canceling trip in track cubit: $error');
      return false;
    } finally {
      _isCancellingTrip = false;
    }
  }

  Future<void> emergencyStop({
    required String reason,
    String details = '',
  }) async {
    await emergencyStopRequest(reason: reason, details: details);
  }

  /// Ends an active ride through the safety-specific server command. The
  /// local tracker is cleared only after the server confirms the transition so
  /// a rejected request can leave the passenger on the active ride screen.
  Future<bool> emergencyStopRequest({
    required String reason,
    String details = '',
  }) async {
    if (isClosed || _isEmergencyStopping) return false;
    _isEmergencyStopping = true;
    try {
      final rideId = (await _sessionService.readActiveRideId() ?? '').trim();
      if (rideId.isEmpty) {
        dev.log('Unable to end passenger trip for safety without a ride id.');
        return false;
      }

      final result = await _repository.emergencyStopResult(
        rideId: rideId,
        reason: reason,
        details: details,
      );
      final failure = result.fold<Failure?>((value) => value, (_) => null);
      if (failure != null) {
        dev.log('Unable to end passenger trip for safety: ${failure.message}');
        return false;
      }

      ++_trackingGeneration;
      unawaited(_trackingTask?.dispose());
      _trackingTask = null;
      _activeTripResync = null;
      _activeRideId = null;
      _lastPassengerLocationPublishedAt = null;
      try {
        await _sessionService.saveActiveRideId('');
      } catch (error, stackTrace) {
        dev.log(
          'Unable to clear the safety-stopped passenger ride locally.',
          error: error,
          stackTrace: stackTrace,
        );
      }
      await _stopBackgroundTelemetry();
      if (!isClosed) emit(const TrackDriverEmergencyStopped());
      return true;
    } catch (error, stackTrace) {
      dev.log(
        'Error ending passenger trip for safety in track cubit.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      _isEmergencyStopping = false;
    }
  }

  String _getEtaLabel(RideStatus status) {
    switch (status) {
      case RideStatus.accepted:
        return 'To Pickup';
      case RideStatus.arrived:
        return 'Arrived';
      case RideStatus.inTransit:
        return 'On Trip';
      default:
        return 'Calculating...';
    }
  }

  @override
  Future<void> close() {
    ++_trackingGeneration;
    _activeRideId = null;
    _lastPassengerLocationPublishedAt = null;
    unawaited(_trackingTask?.dispose());
    _trackingTask = null;
    _activeTripResync = null;
    unawaited(_stopBackgroundTelemetry());
    return super.close();
  }

  bool _isCurrentTrackingOperation(int generation) {
    return !isClosed &&
        !_isEmergencyStopping &&
        generation == _trackingGeneration;
  }

  Future<void> _stopBackgroundTelemetry() async {
    final service = _backgroundTelemetryService;
    if (service == null) return;
    try {
      await service.stop();
    } catch (error) {
      dev.log('Unable to stop passenger background telemetry: $error');
    }
  }
}
