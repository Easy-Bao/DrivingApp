import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver/track_driver_state.dart';
import 'package:passenger/src/features/ride_history/domain/entities/ride_history.dart';
import 'package:passenger/src/infrastructure/session/passenger_session_store.dart';
import 'package:passenger/src/infrastructure/telemetry/passenger_background_telemetry.dart';

class TrackDriverCubit({
  required this._repository,
  required this._sessionService,
  required this._lifecycleCoordinator,
  this._backgroundTelemetryService,
}) extends Cubit<TrackDriverState> {
  final TrackRepository _repository;
  final PassengerSessionStore _sessionService;
  final PassengerBackgroundTelemetry? _backgroundTelemetryService;
  final AppLifecycleCoordinator _lifecycleCoordinator;
  AppLifecyclePeriodicTask? _trackingTask;
  Future<void> Function()? _activeTripResync;
  bool _isSyncing = false;
  int? _syncGeneration;
  int _trackingGeneration = 0;
  bool _isCancellingTrip = false;
  bool _isEmergencyStopping = false;
  RideHistory? currentRide;

  this : super(const TrackDriverInitial());

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
    unawaited(_trackingTask?.dispose());
    _trackingTask = null;
    _activeTripResync = null;

    final session = _sessionService;
    if (rideId.isNotEmpty) {
      await session.saveActiveRideId(rideId);
      if (!_isCurrentTrackingOperation(trackingGeneration)) return;
    }
    final activeRideId = await session.readActiveRideId() ?? '';
    if (!_isCurrentTrackingOperation(trackingGeneration)) return;

    List<List<double>>? routePoints;

    double progress = 0.0;
    var lastDriverLat = startLat;
    var lastDriverLng = startLng;
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
              currentRide = null;
              return;
            }
            if (rideUpdate.status == RideStatus.cancelled) {
              trackingCompleted = true;
              unawaited(_trackingTask?.dispose());
              _trackingTask = null;
              if (identical(_activeTripResync, activeTripResync)) {
                _activeTripResync = null;
              }
              await session.saveActiveRideId('');
              if (!_isCurrentTrackingOperation(trackingGeneration)) return;
              await _stopBackgroundTelemetry();
              if (!_isCurrentTrackingOperation(trackingGeneration)) return;
              currentRide = null;
              emit(const TrackDriverCanceled());
              return;
            }

            double? driverLat;
            double? driverLng;
            DateTime? driverLocationObservedAt;
            bool locationFetched = false;

            final locResult = await _repository.fetchDriverLocationResult(
              activeRideId,
            );
            if (!_isCurrentTrackingOperation(trackingGeneration)) return;
            locResult.fold(
              (failure) {
                dev.log(
                  'Error fetching coordinate location: ${failure.message}',
                );
              },
              (coordinate) {
                driverLat = coordinate.latitude;
                driverLng = coordinate.longitude;
                driverLocationObservedAt = coordinate.observedAt;
                locationFetched = true;
              },
            );

            // A status transition is authoritative even when the location
            // endpoint is temporarily unavailable. Keep the last known
            // coordinate so states such as `arrived` still reach the UI.
            driverLat ??= lastDriverLat;
            driverLng ??= lastDriverLng;
            if (locationFetched) {
              lastDriverLat = driverLat!;
              lastDriverLng = driverLng!;
              lastDriverLocationObservedAt = driverLocationObservedAt;
            }

            final targetLat =
                rideUpdate.destinationLat ??
                (destinationLat == 0 ? null : destinationLat);
            final targetLng =
                rideUpdate.destinationLng ??
                (destinationLng == 0 ? null : destinationLng);
            final now = DateTime.now();
            if (locationFetched &&
                rideUpdate.status != RideStatus.inTransit &&
                _canRetryRoute(pickupRouteLastAttempt, now)) {
              pickupRouteLastAttempt = now;
              final candidate = await _repository.getRoutePolyline(
                startLat: driverLat!,
                startLng: driverLng!,
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
                targetLat != null &&
                targetLng != null &&
                _canRetryRoute(destinationRouteLastAttempt, now)) {
              destinationRouteLastAttempt = now;
              final candidate = await _repository.getRoutePolyline(
                startLat: driverLat!,
                startLng: driverLng!,
                endLat: targetLat,
                endLng: targetLng,
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
                      driverLat: driverLat!,
                      driverLng: driverLng!,
                      progress: progress,
                      eta: eta,
                      routePoints: routePoints,
                      driverName: rideUpdate.driverName,
                      vehiclePlate: rideUpdate.vehiclePlate,
                      vehicleType: rideUpdate.vehicleType,
                    )
                  : TrackDriverInProgress(
                      driverLat: driverLat!,
                      driverLng: driverLng!,
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

  /// Reconciles the mounted trip against one authoritative status/location
  /// snapshot after realtime transport recovery.
  Future<void> resyncActiveTrip() async {
    if (isClosed) return;
    final resync = _activeTripResync;
    if (resync == null) return;
    await resync();
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
      await _stopBackgroundTelemetry();
      currentRide = null;
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
      currentRide = null;
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
