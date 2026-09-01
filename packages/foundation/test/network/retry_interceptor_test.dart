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
