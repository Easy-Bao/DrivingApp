import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  test('ordinary failed reads are attempted once', () async {
    var attempts = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = _FailingHttpClientAdapter(() => attempts++);
    dio.interceptors.add(RetryInterceptor(dio));

    await expectLater(
      dio.get<void>('/api/v1/dashboard'),
      throwsA(isA<DioException>()),
    );

    expect(attempts, 1);
  });

  test('explicit transient reads retain bounded recovery', () async {
    var attempts = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = _FailingHttpClientAdapter(() => attempts++);
    dio.interceptors.add(
      RetryInterceptor(dio, retryDelay: (_) => Duration.zero),
    );

    await expectLater(
      dio.get<void>(
        '/api/v1/bootstrap',
        options: Options(
          extra: {requestRetryPolicyExtraKey: RequestRetryPolicy.transientRead},
        ),
      ),
      throwsA(isA<DioException>()),
    );

    expect(attempts, 3);
  });

  test(
    'app clients can opt ordinary safe reads into bounded recovery',
    () async {
      var attempts = 0;
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = _FailingHttpClientAdapter(() => attempts++);
      dio.interceptors.add(
        RetryInterceptor(
          dio,
          retrySafeReadsByDefault: true,
          retryDelay: (_) => Duration.zero,
        ),
      );

      await expectLater(
        dio.get<void>('/api/v1/dashboard'),
        throwsA(isA<DioException>()),
      );

      expect(attempts, 3);
    },
  );

  test('safe-read defaults do not retry ordinary mutations', () async {
    var attempts = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = _FailingHttpClientAdapter(() => attempts++);
    dio.interceptors.add(
      RetryInterceptor(
        dio,
        retrySafeReadsByDefault: true,
        retryDelay: (_) => Duration.zero,
      ),
    );

    await expectLater(
      dio.post<void>('/api/v1/bids'),
      throwsA(isA<DioException>()),
    );

    expect(attempts, 1);
  });

  test(
    'request metrics count retry attempts and the successful outcome',
    () async {
      final metrics = HttpRequestMetrics();
      final adapter = _RecoveringHttpClientAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = adapter;
      dio.interceptors.add(RequestMetricsInterceptor(metrics));
      dio.interceptors.add(
        RetryInterceptor(
          dio,
          retrySafeReadsByDefault: true,
          retryDelay: (_) => Duration.zero,
        ),
      );

      final response = await dio.get<Map<String, dynamic>>('/api/v1/rides/42');

      expect(response.statusCode, 200);
      expect(adapter.attempts, 2);
      expect(adapter.requestIds, hasLength(2));
      expect(adapter.requestIds.toSet(), hasLength(1));
      expect(adapter.requestIds.first, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(metrics.snapshot(), [
        isA<HttpRequestMetric>()
            .having((metric) => metric.count, 'attempt count', 2)
            .having((metric) => metric.retryCount, 'retry count', 1)
            .having((metric) => metric.successCount, 'success count', 1),
      ]);
    },
  );

  test('explicit read-only POSTs retain bounded recovery', () async {
    var attempts = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = _FailingHttpClientAdapter(() => attempts++);
    dio.interceptors.add(
      RetryInterceptor(dio, retryDelay: (_) => Duration.zero),
    );

    await expectLater(
      dio.post<void>(
        '/api/v1/location/route',
        options: Options(
          extra: {requestRetryPolicyExtraKey: RequestRetryPolicy.transientRead},
        ),
      ),
      throwsA(isA<DioException>()),
    );

    expect(attempts, 3);
  });
}

class _FailingHttpClientAdapter(this.onAttempt) implements HttpClientAdapter {
  final void Function() onAttempt;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) {
    onAttempt();
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
}

class _RecoveringHttpClientAdapter implements HttpClientAdapter {
  int attempts = 0;
  final requestIds = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    attempts++;
    final requestId = options.headers['X-Request-ID'];
    if (requestId is String) requestIds.add(requestId);
    if (attempts == 1) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
