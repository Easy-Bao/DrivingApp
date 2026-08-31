import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:foundation/src/errors/exceptions.dart';

enum NetworkAvailabilityStatus { available, degraded, unavailable }

typedef NetworkNow = DateTime Function();

/// Tracks transport availability for one app process and briefly opens the
/// circuit after consecutive network failures.
///
/// Only the Dio boundary calls [tryAcquireRequest], [recordSuccess], and
/// [recordFailure]. UI consumers subscribe to [changes] for one deduplicated
/// status stream instead of deriving connectivity from individual pages.
final class NetworkAvailabilityCoordinator {
  NetworkAvailabilityCoordinator({
    int failureThreshold = 2,
    Duration cooldown = const Duration(seconds: 5),
    NetworkNow? now,
  }) : assert(failureThreshold > 0),
       assert(cooldown > Duration.zero),
       _failureThreshold = failureThreshold,
       _cooldown = cooldown,
       _now = now ?? DateTime.now;

  final int _failureThreshold;
  final Duration _cooldown;
  final NetworkNow _now;
  final _changes = StreamController<NetworkAvailabilityStatus>.broadcast(
    sync: true,
  );
  NetworkAvailabilityStatus _status = NetworkAvailabilityStatus.available;
  int _consecutiveFailures = 0;
  DateTime? _circuitOpenUntil;
  bool _probeInFlight = false;

  NetworkAvailabilityStatus get status => _status;

  Stream<NetworkAvailabilityStatus> get changes => _changes.stream;

  bool get isCircuitOpen {
    final openUntil = _circuitOpenUntil;
    return openUntil != null && _now().isBefore(openUntil);
  }

  /// Returns false while the circuit is open. Once the cooldown expires, only
  /// one request is admitted as the half-open probe.
  bool tryAcquireRequest() {
    final openUntil = _circuitOpenUntil;
    if (openUntil == null) return true;
    if (_now().isBefore(openUntil) || _probeInFlight) return false;
    _probeInFlight = true;
    return true;
  }

  void recordSuccess() {
    _consecutiveFailures = 0;
    _circuitOpenUntil = null;
    _probeInFlight = false;
    _setStatus(NetworkAvailabilityStatus.available);
  }

  void recordFailure() {
    _probeInFlight = false;
    _consecutiveFailures++;
    if (_consecutiveFailures >= _failureThreshold) {
      _circuitOpenUntil = _now().add(_cooldown);
      _setStatus(NetworkAvailabilityStatus.unavailable);
      return;
    }
    _setStatus(NetworkAvailabilityStatus.degraded);
  }

  Future<void> dispose() => _changes.close();

  void _setStatus(NetworkAvailabilityStatus next) {
    if (_status == next || _changes.isClosed) return;
    _status = next;
    _changes.add(next);
  }

  static bool isNetworkFailure(DioException error) {
    if (error.response != null) return false;
    if (error.error is NetworkCircuitOpenException) return false;
    return error.error is SocketException ||
        switch (error.type) {
          DioExceptionType.connectionError ||
          DioExceptionType.connectionTimeout ||
          DioExceptionType.sendTimeout ||
          DioExceptionType.receiveTimeout => true,
          _ => false,
        };
  }
}

/// Applies the process-wide availability circuit to a Dio client.
final class NetworkAvailabilityInterceptor extends Interceptor {
  const NetworkAvailabilityInterceptor(this.coordinator);

  final NetworkAvailabilityCoordinator coordinator;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!coordinator.tryAcquireRequest()) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: const NetworkCircuitOpenException(),
        ),
      );
      return;
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    coordinator.recordSuccess();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (NetworkAvailabilityCoordinator.isNetworkFailure(err)) {
      coordinator.recordFailure();
    }
    handler.next(err);
  }
}
