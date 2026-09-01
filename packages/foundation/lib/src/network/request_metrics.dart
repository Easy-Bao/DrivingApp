import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

final class const HttpRequestMetric({
  required this.method,
  required this.path,
  required this.count,
}) extends Equatable {
  final String method;
  final String path;
  final int count;

  @override
  List<Object> get props => [method, path, count];
}

/// Captures development-time request volume without retaining query values or
/// path identifiers that could expose account, ride, or location data.
final class HttpRequestMetrics() {
  static final HttpRequestMetrics instance = HttpRequestMetrics();

  final Map<({String method, String path}), int> _counts =
      <({String method, String path}), int>{};

  int get totalCount => _counts.values.fold(0, (total, count) => total + count);

  void record(RequestOptions options) {
    final key = (
      method: options.method.toUpperCase(),
      path: _normalizePath(options.uri.path),
    );
    _counts.update(key, (count) => count + 1, ifAbsent: () => 1);
  }

  List<HttpRequestMetric> snapshot() {
    final metrics =
        _counts.entries
            .map(
              (entry) => HttpRequestMetric(
                method: entry.key.method,
                path: entry.key.path,
                count: entry.value,
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

  void clear() => _counts.clear();
}

final class RequestMetricsInterceptor(this._metrics) extends Interceptor {
  final HttpRequestMetrics _metrics;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _metrics.record(options);
    handler.next(options);
  }
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
      _uuidIdentifier.hasMatch(segment)) {
    return ':id';
  }
  return segment;
}

final RegExp _numericIdentifier = RegExp(r'^\d+$');
final RegExp _uuidIdentifier = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
);
