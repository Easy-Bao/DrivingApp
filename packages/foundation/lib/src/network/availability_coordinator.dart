import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:foundation/src/errors/exceptions.dart';
import 'package:foundation/src/errors/network_diagnostic.dart';

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
  Duration serviceFailureTtl = const Duration(seconds: 30),
  Duration probeTimeout = const Duration(seconds: 30),
  NetworkNow? now,
}) {
  this
    : assert(failureThreshold > 0),
      assert(cooldown > Duration.zero),
      assert(serviceFailureTtl > Duration.zero),
      assert(probeTimeout > Duration.zero),
      _failureThreshold = failureThreshold,
      _cooldown = cooldown,
      _serviceFailureTtl = serviceFailureTtl,
      _probeTimeout = probeTimeout,
      _now = now ?? DateTime.now;

  static const int _maxTrackedFailedEndpoints = 64;
  static final RegExp _numericSegment = RegExp(r'^\d+$');
  static final RegExp _uuidSegment = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  final int _failureThreshold;
  final Duration _cooldown;
  final Duration _serviceFailureTtl;
  final Duration _probeTimeout;
  final NetworkNow _now;
  final _changes = StreamController<NetworkAvailabilityStatus>.broadcast(
    sync: true,
  );
  NetworkAvailabilityStatus _status = NetworkAvailabilityStatus.available;
  final Map<(String, String), DateTime> _failedEndpoints = {};
  int _consecutiveFailures = 0;
  DateTime? _circuitOpenUntil;
  bool _probeInFlight = false;
  DateTime? _probeStartedAt;
  int _successGeneration = 0;
  NetworkErrorCategory? _lastFailureCategory;

  int get successGeneration => _successGeneration;

  NetworkErrorCategory? get lastFailureCategory => _lastFailureCategory;

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
    final currentTime = _now();
    if (currentTime.isBefore(openUntil)) return false;
    if (_probeInFlight) {
      final startedAt = _probeStartedAt;
      if (startedAt == null ||
          currentTime.difference(startedAt) < _probeTimeout) {
        return false;
      }
    }
    _probeInFlight = true;
    _probeStartedAt = currentTime;
    return true;
  }

  void recordSuccess() {
    _pruneExpiredEndpointFailures();
    _successGeneration++;
    _consecutiveFailures = 0;
    _circuitOpenUntil = null;
    _probeInFlight = false;
    _probeStartedAt = null;
    _lastFailureCategory = null;
    _setStatus(
      _failedEndpoints.isEmpty
          ? NetworkAvailabilityStatus.available
          : NetworkAvailabilityStatus.serviceUnavailable,
    );
  }

  /// HTTP failures affect service availability without opening the connection
  /// circuit. Normalized endpoint failures expire automatically or clear as
  /// soon as the endpoint responds normally.
  void recordResponse(Response<dynamic> response) {
    final code = response.statusCode;
    if (code == null) {
      releaseProbe();
      return;
    }
    final request = response.requestOptions;
    final endpoint = (
      request.method.toUpperCase(),
      _normalizeEndpointKey(request.uri),
    );
    _pruneExpiredEndpointFailures();
    if (code >= 500 && code < 600) {
      _failedEndpoints.remove(endpoint);
      _failedEndpoints[endpoint] = _now().add(_serviceFailureTtl);
      while (_failedEndpoints.length > _maxTrackedFailedEndpoints) {
        _failedEndpoints.remove(_failedEndpoints.keys.first);
      }
    } else {
      _failedEndpoints.remove(endpoint);
    }
    recordSuccess();
  }

  /// Frees the half-open probe slot without judging network health, for
  /// requests that ended before reaching the server (e.g. cancellation).
  void releaseProbe() {
    _probeInFlight = false;
    _probeStartedAt = null;
  }

  void recordFailure({int? requestGeneration, NetworkErrorCategory? category}) {
    // An older request timing out cannot overturn a response that reached the
    // server after that request began. Only fresh failures judge recovery.
    if (requestGeneration != null && requestGeneration != _successGeneration) {
      return;
    }
    _probeInFlight = false;
    _probeStartedAt = null;
    if (category != null) _lastFailureCategory = category;
    _consecutiveFailures++;
    if (_consecutiveFailures >= _failureThreshold) {
      _circuitOpenUntil = _now().add(_cooldown);
      _setStatus(NetworkAvailabilityStatus.unavailable);
      return;
    }
    _setStatus(NetworkAvailabilityStatus.degraded);
  }

  Future<void> dispose() => _changes.close();

  void _pruneExpiredEndpointFailures() {
    if (_failedEndpoints.isEmpty) return;
    final currentTime = _now();
    _failedEndpoints.removeWhere(
      (_, expiresAt) => !currentTime.isBefore(expiresAt),
    );
  }

  static String _normalizeEndpointKey(Uri uri) {
    final normalizedPath = uri.path
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .map(
          (segment) =>
              _numericSegment.hasMatch(segment) ||
                  _uuidSegment.hasMatch(segment)
              ? ':id'
              : segment,
        )
        .join('/');
    return uri.replace(path: '/$normalizedPath', query: '').toString();
  }

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
          error: NetworkCircuitOpenException(
            category:
                coordinator.lastFailureCategory ??
                NetworkErrorCategory.connectionError,
          ),
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
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (NetworkAvailabilityCoordinator.isNetworkFailure(err)) {
      coordinator.recordFailure(
        requestGeneration: err.requestOptions.extra[_generationKey] as int?,
        category: NetworkErrorDiagnostic.fromError(err).category,
      );
    } else if (err.response case final response?) {
      coordinator.recordResponse(response);
    } else if (err.error is! NetworkCircuitOpenException) {
      coordinator.releaseProbe();
    }
    handler.next(err);
  }
}
