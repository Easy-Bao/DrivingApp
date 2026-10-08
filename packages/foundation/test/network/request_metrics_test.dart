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

  test(
    'captures safe per-attempt timing, status, retries, and byte counts',
    () {
      final metrics = HttpRequestMetrics();
      final request = RequestOptions(
        method: 'POST',
        baseUrl: 'https://api.example',
        path: '/api/v1/rides/42',
        queryParameters: {'token': 'private-value'},
        headers: {Headers.contentLengthHeader: '5'},
        data: 'hello',
      );

      metrics.record(request);
      request.extra['retryAttempt'] = 1;
      metrics.record(request);
      metrics.recordResponse(
        Response<dynamic>(
          requestOptions: request,
          statusCode: 201,
          headers: Headers.fromMap({
            Headers.contentLengthHeader: ['7'],
          }),
        ),
      );

      final metric = metrics.snapshot().single;
      expect(metric.method, 'POST');
      expect(metric.path, '/api/v1/rides/:id');
      expect(metric.path, isNot(contains('private-value')));
      expect(metric.count, 2);
      expect(metric.successCount, 1);
      expect(metric.retryCount, 1);
      expect(metric.requestBytes, 10);
      expect(metric.requestByteSamples, 2);
      expect(metric.responseBytes, 7);
      expect(metric.responseByteSamples, 1);
      expect(metric.totalDurationMicroseconds, greaterThanOrEqualTo(0));
      expect(metric.maxDurationMicroseconds, greaterThanOrEqualTo(0));
      expect(metric.statusCodes, {201: 1});
    },
  );

  test('records failure and cancellation outcomes without request data', () {
    final metrics = HttpRequestMetrics();
    final failedRequest = RequestOptions(
      method: 'GET',
      baseUrl: 'https://api.example',
      path: '/api/v1/profile',
    );
    metrics.record(failedRequest);
    metrics.recordError(
      DioException(
        requestOptions: failedRequest,
        type: DioExceptionType.connectionTimeout,
      ),
    );

    final cancelledRequest = RequestOptions(
      method: 'GET',
      baseUrl: 'https://api.example',
      path: '/api/v1/profile',
    );
    metrics.record(cancelledRequest);
    metrics.recordError(
      DioException(
        requestOptions: cancelledRequest,
        type: DioExceptionType.cancel,
      ),
    );

    final metric = metrics.snapshot().single;
    expect(metric.count, 2);
    expect(metric.failureCount, 1);
    expect(metric.cancelledCount, 1);
    expect(metric.statusCodes, isEmpty);
  });
}
