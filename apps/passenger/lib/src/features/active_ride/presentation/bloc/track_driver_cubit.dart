import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/core/telemetry/background_telemetry.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver_state.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver_sync_session.dart';

class TrackDriverCubit extends Cubit<TrackDriverState> {
  TrackDriverCubit({
    required this.repository,
    required this.sessionService,
    required this.lifecycleCoordinator,
    this.backgroundTelemetryService,
    this.pollInterval = const Duration(seconds: 2),
  }) : super(const TrackDriverInitial());

  final TrackRepository repository;
  final SessionStore sessionService;
  final BackgroundTelemetry? backgroundTelemetryService;
  final AppLifecycleCoordinator lifecycleCoordinator;
  final Duration pollInterval;

  AppLifecyclePeriodicTask? _trackingTask;
  Future<void> Function()? _activeTripResync;
  int _trackingGeneration = 0;
  String? _activeRideId;
  DateTime? _lastPassengerLocationPublishedAt;
  bool _isCancellingTrip = false;
  bool _isEmergencyStopping = false;

  Future<void> resetTracking() async {
    if (isClosed) return;
    _clearTrackingState();
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
    _disposeTrackingTask();

    final session = sessionService;
    late final String activeRideId;
    try {
      if (rideId.isNotEmpty) {
        await session.saveActiveRideId(rideId);
        if (!_isCurrentTrackingOperation(trackingGeneration)) return;
      }
      activeRideId = await session.readActiveRideId() ?? '';
    } catch (_) {
      if (_isCurrentTrackingOperation(trackingGeneration)) {
        _activeRideId = null;
        _lastPassengerLocationPublishedAt = null;
      }
      rethrow;
    }
    if (!_isCurrentTrackingOperation(trackingGeneration)) return;
    _activeRideId = activeRideId.isEmpty ? null : activeRideId;

    final syncSession = TrackDriverSyncSession(
      activeRideId: activeRideId,
      fallbackDriverId: driverId,
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      generation: trackingGeneration,
      repository: repository,
      sessionService: session,
      lifecycleCoordinator: lifecycleCoordinator,
      isCurrentOperation: _isCurrentTrackingOperation,
      onEmit: emit,
      onClearTrackingState: (expectedResync) => _clearTrackingState(
        bumpGeneration: false,
        expectedResync: expectedResync,
      ),
      onStopBackgroundTelemetry: _stopBackgroundTelemetry,
    );

    _activeTripResync = syncSession.sync;

    if (lifecycleCoordinator.isForeground &&
        _isCurrentTrackingOperation(trackingGeneration)) {
      await syncSession.sync();
    }
    if (!syncSession.isCompleted &&
        _isCurrentTrackingOperation(trackingGeneration)) {
      final task = AppLifecyclePeriodicTask(
        lifecycleCoordinator: lifecycleCoordinator,
        interval: pollInterval,
        onTick: syncSession.sync,
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
      final result = await repository.publishPassengerLocationResult(
        rideId: activeRideId,
        latitude: latitude,
        longitude: longitude,
      );
      if (result case Err(:final failure)) {
        dev.log('Passenger telemetry update failed: ${failure.message}');
      }
    } catch (error, stackTrace) {
      dev.log(
        'Passenger telemetry update failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
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
    _isCancellingTrip = true;
    try {
      final storedRideId = (await sessionService.readActiveRideId() ?? '')
          .trim();
      final rideId = storedRideId.isNotEmpty
          ? storedRideId
          : (_activeRideId ?? '').trim();
      if (rideId.isNotEmpty) {
        final result = await repository.cancelRideResult(
          rideId: rideId,
          reason: reason,
          details: details,
        );
        if (result case Err(:final failure)) {
          dev.log('Unable to cancel passenger trip: ${failure.message}');
          return false;
        }
        try {
          await sessionService.saveActiveRideId('');
        } catch (error, stackTrace) {
          dev.log(
            'Unable to clear the canceled passenger ride locally.',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }

      _clearTrackingState();
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
      final storedRideId = (await sessionService.readActiveRideId() ?? '')
          .trim();
      final rideId = storedRideId.isNotEmpty
          ? storedRideId
          : (_activeRideId ?? '').trim();
      if (rideId.isEmpty) {
        dev.log('Unable to end passenger trip for safety without a ride id.');
        return false;
      }

      final result = await repository.emergencyStopResult(
        rideId: rideId,
        reason: reason,
        details: details,
      );
      if (result case Err(:final failure)) {
        dev.log('Unable to end passenger trip for safety: ${failure.message}');
        return false;
      }

      _clearTrackingState();
      try {
        await sessionService.saveActiveRideId('');
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

  @override
  Future<void> close() {
    _clearTrackingState();
    unawaited(_stopBackgroundTelemetry());
    return super.close();
  }

  void _disposeTrackingTask({Future<void> Function()? expectedResync}) {
    unawaited(_trackingTask?.dispose());
    _trackingTask = null;
    if (expectedResync == null ||
        identical(_activeTripResync, expectedResync)) {
      _activeTripResync = null;
    }
  }

  void _clearTrackingState({
    bool bumpGeneration = true,
    Future<void> Function()? expectedResync,
  }) {
    if (bumpGeneration) {
      ++_trackingGeneration;
    }
    _activeRideId = null;
    _lastPassengerLocationPublishedAt = null;
    _disposeTrackingTask(expectedResync: expectedResync);
  }

  bool _isCurrentTrackingOperation(int generation) {
    return !isClosed &&
        !_isCancellingTrip &&
        !_isEmergencyStopping &&
        generation == _trackingGeneration;
  }

  Future<void> _stopBackgroundTelemetry() async {
    final service = backgroundTelemetryService;
    if (service == null) return;
    try {
      await service.stop();
    } catch (error) {
      dev.log('Unable to stop passenger background telemetry: $error');
    }
  }
}
