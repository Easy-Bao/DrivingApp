import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:foundation/src/network/retry_interceptor.dart';
import 'package:foundation/src/telemetry/correlation_id.dart';

const bool _isReleaseMode = bool.fromEnvironment('dart.vm.product');

final class const HttpRequestMetric({
  required this.method,
  required this.path,
  required this.count,
  this.successCount = 0,
  this.failureCount = 0,
  this.cancelledCount = 0,
  this.retryCount = 0,
  this.requestBytes = 0,
  this.requestByteSamples = 0,
  this.responseBytes = 0,
  this.responseByteSamples = 0,
  this.totalDurationMicroseconds = 0,
  this.maxDurationMicroseconds = 0,
  this.statusCodes = const {},
}) extends Equatable {
  final String method;
  final String path;

  /// Number of network attempts, including retries.
  final int count;
  final int successCount;
  final int failureCount;
  final int cancelledCount;
  final int retryCount;
  final int requestBytes;
  final int requestByteSamples;
  final int responseBytes;
  final int responseByteSamples;
  final int totalDurationMicroseconds;
  final int maxDurationMicroseconds;
  final Map<int, int> statusCodes;

  @override
  List<Object> get props => [
    method,
    path,
    count,
    successCount,
    failureCount,
    cancelledCount,
    retryCount,
    requestBytes,
    requestByteSamples,
    responseBytes,
    responseByteSamples,
    totalDurationMicroseconds,
    maxDurationMicroseconds,
    statusCodes,
  ];
}

/// Captures development-time request volume and timing without retaining
/// headers, bodies, query values, or raw numeric/UUID path identifiers.
final class HttpRequestMetrics({int maxTrackedRoutes = 256}) {
  this : assert(maxTrackedRoutes > 0), _maxTrackedRoutes = maxTrackedRoutes;

  static final HttpRequestMetrics instance = HttpRequestMetrics();

  final int _maxTrackedRoutes;
  final Map<({String method, String path}), _RequestMetricAccumulator>
  _metrics = <({String method, String path}), _RequestMetricAccumulator>{};

  int get totalCount =>
      _metrics.values.fold(0, (total, metric) => total + metric.count);

  void record(RequestOptions options) {
    final metric = _metricFor(options);
    metric.recordRequest(options);
  }

  void recordResponse(Response<dynamic> response) {
    final metric = _metricFor(response.requestOptions);
    metric.recordResponse(response);
  }

  void recordError(DioException error) {
    final metric = _metricFor(error.requestOptions);
    metric.recordError(error);
  }

  List<HttpRequestMetric> snapshot() {
    final metrics =
        _metrics.entries
            .map(
              (entry) => HttpRequestMetric(
                method: entry.key.method,
                path: entry.key.path,
                count: entry.value.count,
                successCount: entry.value.successCount,
                failureCount: entry.value.failureCount,
                cancelledCount: entry.value.cancelledCount,
                retryCount: entry.value.retryCount,
                requestBytes: entry.value.requestBytes,
                requestByteSamples: entry.value.requestByteSamples,
                responseBytes: entry.value.responseBytes,
                responseByteSamples: entry.value.responseByteSamples,
                totalDurationMicroseconds:
                    entry.value.totalDurationMicroseconds,
                maxDurationMicroseconds: entry.value.maxDurationMicroseconds,
                statusCodes: Map.unmodifiable(entry.value.statusCodes),
              ),
            )
            .toList()
          ..sort((left, right) {
            final methodComparison = left.method.compareTo(right.method);
            return methodComparison != 0
                ? methodComparison
                : left.path.compareTo(right.path);
          });
    return List.unmodifiable(metrics);
  }

  void clear() => _metrics.clear();

  _RequestMetricAccumulator _metricFor(RequestOptions options) {
    final cachedPath = options.extra[_normalizedPathKey];
    final normalizedPath = cachedPath is String
        ? cachedPath
        : _normalizePath(options.uri.path);
    options.extra[_normalizedPathKey] = normalizedPath;
    final key = (method: options.method.toUpperCase(), path: normalizedPath);
    final existing = _metrics[key];
    if (existing != null) return existing;
    while (_metrics.length >= _maxTrackedRoutes) {
      _metrics.remove(_metrics.keys.first);
    }
    return _metrics[key] = _RequestMetricAccumulator();
  }
}

final class RequestMetricsInterceptor(this._metrics) extends Interceptor {
  final HttpRequestMetrics _metrics;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isReleaseMode) {
      handler.next(options);
      return;
    }

    final requestId = _ensureRequestCorrelationId(options.headers);
    final previousTask = options.extra.remove(_requestTimelineTaskKey);
    if (previousTask is developer.TimelineTask) {
      previousTask.finish(arguments: const {'outcome': 'superseded'});
    }
    _metrics.record(options);
    final normalizedPath =
        options.extra[_normalizedPathKey] as String? ??
        _normalizePath(options.uri.path);
    final retryAttempt = options.extra[retryAttemptExtraKey];
    final arguments = <String, Object?>{
      'method': options.method.toUpperCase(),
      'path': normalizedPath,
      'retry_attempt': retryAttempt is int ? retryAttempt : 0,
      'request_bytes':
          _knownBodyBytes(options.data) ??
          _contentLength(options.headers) ??
          -1,
    };
    if (requestId != null) arguments['request_id'] = requestId;
    final task = developer.TimelineTask()
      ..start('http.request', arguments: arguments);
    options.extra[_requestTimelineTaskKey] = task;
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (!_isReleaseMode) {
      _metrics.recordResponse(response);
      _finishRequestTimeline(
        response.requestOptions,
        outcome: 'response',
        statusCode: response.statusCode,
        responseBytes: _contentLength(response.headers.map),
        requestId: _requestCorrelationId(response.requestOptions.headers),
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!_isReleaseMode) {
      _metrics.recordError(err);
      final responseBytes = switch (err.response) {
        final response? => _contentLength(response.headers.map),
        null => null,
      };
      _finishRequestTimeline(
        err.requestOptions,
        outcome: err.type == DioExceptionType.cancel ? 'cancelled' : 'error',
        statusCode: err.response?.statusCode,
        responseBytes: responseBytes,
        requestId: _requestCorrelationId(err.requestOptions.headers),
      );
    }
    handler.next(err);
  }

  void _finishRequestTimeline(
    RequestOptions options, {
    required String outcome,
    required int? statusCode,
    required int? responseBytes,
    required String? requestId,
  }) {
    final task = options.extra.remove(_requestTimelineTaskKey);
    if (task is! developer.TimelineTask) return;
    final arguments = <String, Object?>{
      'outcome': outcome,
      'status_code': statusCode ?? -1,
      'response_bytes': responseBytes ?? -1,
    };
    if (requestId != null) arguments['request_id'] = requestId;
    task.finish(arguments: arguments);
  }
}

final class _RequestMetricAccumulator {
  int count = 0;
  int successCount = 0;
  int failureCount = 0;
  int cancelledCount = 0;
  int retryCount = 0;
  int requestBytes = 0;
  int requestByteSamples = 0;
  int responseBytes = 0;
  int responseByteSamples = 0;
  int totalDurationMicroseconds = 0;
  int maxDurationMicroseconds = 0;
  final Map<int, int> statusCodes = <int, int>{};

  void recordRequest(RequestOptions options) {
    count++;
    final retryAttempt = options.extra[retryAttemptExtraKey];
    if (retryAttempt is int && retryAttempt > 0) retryCount++;

    final requestBytesForAttempt =
        _knownBodyBytes(options.data) ?? _contentLength(options.headers);
    if (requestBytesForAttempt != null) {
      requestBytes += requestBytesForAttempt;
      requestByteSamples++;
    }
    options.extra[_requestTimerKey] = Stopwatch()..start();
  }

  void recordResponse(Response<dynamic> response) {
    successCount++;
    _recordStatusCode(response.statusCode);
    _recordDuration(response.requestOptions);

    final bytes = _contentLength(response.headers.map);
    if (bytes != null) {
      responseBytes += bytes;
      responseByteSamples++;
    }
  }

  void recordError(DioException error) {
    if (error.type == DioExceptionType.cancel) {
      cancelledCount++;
    } else {
      failureCount++;
    }
    _recordStatusCode(error.response?.statusCode);
    _recordDuration(error.requestOptions);
  }

  void _recordStatusCode(int? statusCode) {
    if (statusCode == null) return;
    statusCodes.update(statusCode, (count) => count + 1, ifAbsent: () => 1);
  }

  void _recordDuration(RequestOptions options) {
    final timer = options.extra[_requestTimerKey];
    if (timer is! Stopwatch) return;

    timer.stop();
    final elapsedMicroseconds = timer.elapsedMicroseconds;
    totalDurationMicroseconds += elapsedMicroseconds;
    if (elapsedMicroseconds > maxDurationMicroseconds) {
      maxDurationMicroseconds = elapsedMicroseconds;
    }
    options.extra.remove(_requestTimerKey);
  }
}

const _requestTimerKey = 'foundation.requestMetrics.stopwatch';
const _requestTimelineTaskKey = 'foundation.requestMetrics.timelineTask';
const _normalizedPathKey = 'foundation.requestMetrics.normalizedPath';
const _requestIdHeader = 'X-Request-ID';

String? _ensureRequestCorrelationId(Map<String, dynamic> headers) {
  final existingId = _requestCorrelationId(headers);
  if (existingId != null) return existingId;

  headers.removeWhere(
    (key, _) => key.toLowerCase() == _requestIdHeader.toLowerCase(),
  );
  final requestId = newRequestCorrelationId();
  headers[_requestIdHeader] = requestId;
  return requestId;
}

String? _requestCorrelationId(Map<String, dynamic> headers) {
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() != _requestIdHeader.toLowerCase()) continue;
    final value = entry.value;
    if (value is String && _safeRequestId.hasMatch(value)) return value;
  }
  return null;
}

int? _knownBodyBytes(Object? body) {
  if (body is List<int>) return body.length;
  return null;
}

int? _contentLength(Map<String, dynamic> headers) {
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() != Headers.contentLengthHeader.toLowerCase()) {
      continue;
    }

    final value = entry.value;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is List && value.isNotEmpty) {
      final firstValue = value.first;
      if (firstValue is int) return firstValue;
      if (firstValue is String) return int.tryParse(firstValue);
    }
  }
  return null;
}

String _normalizePath(String path) {
  final segments = path
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .map(_normalizeSegment);
  return '/${segments.join('/')}';
}

String _normalizeSegment(String segment) {
  if (_numericIdentifier.hasMatch(segment) ||
      _uuidIdentifier.hasMatch(segment) ||
      _ulidIdentifier.hasMatch(segment)) {
    return ':id';
  }
  return segment;
}

final RegExp _numericIdentifier = RegExp(r'^\d+$');
final RegExp _uuidIdentifier = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);
final RegExp _ulidIdentifier = RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$');
final RegExp _safeRequestId = RegExp(r'^[A-Za-z0-9._-]{8,128}$');
