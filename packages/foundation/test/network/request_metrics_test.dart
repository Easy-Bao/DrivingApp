import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  test('groups dynamic numeric and UUID path segments without query data', () {
    final metrics = HttpRequestMetrics();

    metrics.record(
      RequestOptions(baseUrl: 'https://api.example', path: '/api/v1/rides/42'),
    );
    metrics.record(
      RequestOptions(baseUrl: 'https://api.example', path: '/api/v1/rides/43'),
    );
    metrics.record(
      RequestOptions(
        method: 'POST',
        baseUrl: 'https://api.example',
        path: '/api/v1/rides/550e8400-e29b-41d4-a716-446655440000/offers',
      ),
    );

    expect(metrics.totalCount, 3);
    expect(metrics.snapshot(), const [
      HttpRequestMetric(method: 'GET', path: '/api/v1/rides/:id', count: 2),
      HttpRequestMetric(
        method: 'POST',
        path: '/api/v1/rides/:id/offers',
        count: 1,
      ),
    ]);
  });

  test('clears a captured measurement window', () {
    final metrics = HttpRequestMetrics();
    metrics.record(RequestOptions(path: '/health'));

    metrics.clear();

    expect(metrics.totalCount, 0);
    expect(metrics.snapshot(), isEmpty);
  });
}
