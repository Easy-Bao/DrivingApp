import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:foundation/src/errors/exceptions.dart';

enum NetworkAvailabilityStatus {
  available,
  degraded,
  unavailable,
  serviceUnavailable;

  bool get isConnectionUnavailable => this == unavailable;

  bool get hasAvailabilityWarning =>
      isConnectionUnavailable || this == serviceUnavailable;
}

typedef NetworkNow = DateTime Function();

/// Only the Dio boundary calls [tryAcquireRequest], [recordSuccess], and
/// [recordFailure]. UI consumers subscribe to [changes] for one deduplicated
/// status stream instead of deriving connectivity from individual pages.
final class NetworkAvailabilityCoordinator({
  int failureThreshold = 2,
  Duration cooldown = const Duration(seconds: 5),
  NetworkNow? now,
}) {
  this
    : assert(failureThreshold > 0),
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
  final Set<(String, String)> _failedEndpoints = {};
  int _consecutiveFailures = 0;
  DateTime? _circuitOpenUntil;
  bool _probeInFlight = false;
  int _successGeneration = 0;

  int get successGeneration => _successGeneration;

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
    _successGeneration++;
    _consecutiveFailures = 0;
    _circuitOpenUntil = null;
    _probeInFlight = false;
    _setStatus(
      _failedEndpoints.isEmpty
          ? NetworkAvailabilityStatus.available
          : NetworkAvailabilityStatus.serviceUnavailable,
    );
  }

  /// HTTP failures affect service availability without opening the connection
  /// circuit. Only a response from the affected endpoint clears its failure.
  void recordResponse(Response<dynamic> response) {
    final code = response.statusCode;
    if (code == null) {
      releaseProbe();
      return;
    }
    final request = response.requestOptions;
    final endpoint = (
      request.method,
      request.uri.replace(query: '').toString(),
    );
    if (code >= 500 && code < 600) {
      _failedEndpoints.add(endpoint);
    } else {
      _failedEndpoints.remove(endpoint);
    }
    recordSuccess();
  }

  /// Frees the half-open probe slot without judging network health, for
  /// requests that ended before reaching the server (e.g. cancellation).
  void releaseProbe() {
    _probeInFlight = false;
  }

  void recordFailure({int? requestGeneration}) {
    // An older request timing out cannot overturn a response that reached the
    // server after that request began. Only fresh failures judge recovery.
    if (requestGeneration != null && requestGeneration != _successGeneration) {
      return;
    }
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

final class const NetworkAvailabilityInterceptor(this.coordinator)
    extends Interceptor {
  final NetworkAvailabilityCoordinator coordinator;
  static const _generationKey = 'foundation.network.successGeneration';

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
    options.extra[_generationKey] = coordinator.successGeneration;
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    coordinator.recordResponse(response);
    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    if (NetworkAvailabilityCoordinator.isNetworkFailure(error)) {
      coordinator.recordFailure(
        requestGeneration: error.requestOptions.extra[_generationKey] as int?,
      );
    } else if (error.response != null) {
      coordinator.recordResponse(error.response!);
    } else if (error.error is! NetworkCircuitOpenException) {
      coordinator.releaseProbe();
    }
    handler.next(error);
  }
}
