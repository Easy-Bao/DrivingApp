import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  test('adds an idempotency key to state-changing requests', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    RequestOptions? captured;
    dio.interceptors.add(IdempotencyInterceptor());
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.reject(DioException(requestOptions: options));
        },
      ),
    );

    await expectLater(
      dio.post<void>('/api/v1/rides'),
      throwsA(isA<DioException>()),
    );

    expect(captured?.headers['Idempotency-Key'], isA<String>());
    expect(
      captured!.headers['Idempotency-Key'].toString().length,
      greaterThan(8),
    );
  });

  test('does not add a key to safe read requests', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    RequestOptions? captured;
    dio.interceptors.add(IdempotencyInterceptor());
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.reject(DioException(requestOptions: options));
        },
      ),
    );

    await expectLater(dio.get<void>('/health'), throwsA(isA<DioException>()));

    expect(captured?.headers.containsKey('Idempotency-Key'), isFalse);
  });

  for (final path in <String>[
    '/api/v1/auth/passenger/login',
    '/api/v1/telemetry/location',
    '/api/v1/location/route',
    '/api/v1/bids/fare',
    '/api/v1/driver/documents',
    '/api/v1/drivers/42/online',
  ]) {
    test('does not add a key to $path', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      RequestOptions? captured;
      dio.interceptors.add(IdempotencyInterceptor());
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            handler.reject(DioException(requestOptions: options));
          },
        ),
      );

      await expectLater(dio.post<void>(path), throwsA(isA<DioException>()));

      expect(captured?.headers.containsKey('Idempotency-Key'), isFalse);
    });
  }
}
