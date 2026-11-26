import 'dart:async';
import 'dart:developer' as dev;

import 'package:driver/src/core/session/session_store.dart';

bool isValidCoordinatePair(double? latitude, double? longitude) {
  return latitude != null &&
      longitude != null &&
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

final class RideFlowSessionCoordinator {
  RideFlowSessionCoordinator({required this._sessionService});

  final SessionStore _sessionService;
  Future<void> _activeRideIdWriteQueue = Future<void>.value();

  Future<String?> readDriverId() => _sessionService.readDriverId();

  Future<void> clearActiveRideSession() => _serializeWrite(() async {
    try {
      await _sessionService.clearActiveRideId();
    } catch (error, stackTrace) {
      dev.log(
        'Unable to clear the locally cached active ride',
        error: error,
        stackTrace: stackTrace,
      );
    }
  });

  Future<void> saveActiveRideSession(String rideId) =>
      _serializeWrite(() async {
        try {
          await _sessionService.saveActiveRideId(rideId);
        } catch (error, stackTrace) {
          dev.log(
            'Unable to cache the active ride for recovery',
            error: error,
            stackTrace: stackTrace,
          );
        }
      });

  Future<void> _serializeWrite(Future<void> Function() write) {
    final operation = _activeRideIdWriteQueue.then((_) => write());
    _activeRideIdWriteQueue = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return operation;
  }
}

final class RideFlowWaitTracker {
  static const _noShowClockSkewBuffer = Duration(seconds: 5);

  Timer? _timer;
  DateTime? _waitingUntil;
  DateTime? _waitStartedAt;

  DateTime? get waitingUntil => _waitingUntil;
  DateTime? get waitStartedAt => _waitStartedAt;

  DateTime? get _eligibleAt => _waitingUntil?.add(_noShowClockSkewBuffer);

  bool get canMarkPassengerNoShow {
    final eligibleAt = _eligibleAt;
    return eligibleAt != null && !DateTime.now().toUtc().isBefore(eligibleAt);
  }

  Duration? get passengerNoShowTimeRemaining {
    final eligibleAt = _eligibleAt;
    if (eligibleAt == null) return null;
    final remaining = eligibleAt.difference(DateTime.now().toUtc());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void configure({DateTime? waitingUntil, DateTime? waitStartedAt}) {
    _waitingUntil = waitingUntil?.toUtc();
    _waitStartedAt = waitStartedAt?.toUtc();
  }

  void clear() {
    _timer?.cancel();
    _timer = null;
    _waitingUntil = null;
    _waitStartedAt = null;
  }

  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  int elapsedWaitSeconds() {
    final start = _waitStartedAt ?? DateTime.now().toUtc();
    final elapsed = DateTime.now().toUtc().difference(start).inSeconds;
    return elapsed.clamp(0, 24 * 60 * 60).toInt();
  }

  void start({
    required bool Function() isActive,
    required void Function(int elapsedSeconds) onTick,
  }) {
    _timer?.cancel();
    _waitStartedAt ??= DateTime.now().toUtc();
    if (!isActive()) return;
    onTick(elapsedWaitSeconds());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isActive()) {
        _timer?.cancel();
        _timer = null;
        return;
      }
      onTick(elapsedWaitSeconds());
    });
  }
}
