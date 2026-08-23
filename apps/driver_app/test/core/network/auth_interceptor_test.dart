import 'package:dio/dio.dart';
import 'package:driver_app/src/core/network/interceptors/auth_interceptor.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

class MockDio extends Mock implements Dio {}

class MockSecureSessionService extends Mock implements SecureSessionService {}

class FakeRequestOptions extends Fake implements RequestOptions {}

class FakeResponse extends Fake implements Response<dynamic> {}

class FakeDioException extends Fake implements DioException {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(FakeResponse());
    registerFallbackValue(FakeDioException());
  });

  test('adds the securely stored token to authenticated requests', () async {
    final secureSessionService = MockSecureSessionService();
    final handler = MockRequestInterceptorHandler();
    final requestOptions = RequestOptions(path: '/api/v1/telemetry/location');
    when(
      () => secureSessionService.readToken(),
    ).thenAnswer((_) async => 'jwt-token');

    await AuthInterceptor(
      secureSessionService,
    ).onRequest(requestOptions, handler);

    expect(requestOptions.headers['Authorization'], 'Bearer jwt-token');
    verify(() => handler.next(requestOptions)).called(1);
  });

  test('does not send the session token to another origin', () async {
    final secureSessionService = MockSecureSessionService();
    final handler = MockRequestInterceptorHandler();
    final requestOptions = RequestOptions(
      baseUrl: 'https://attacker.example',
      path: '/collect',
    );
    when(
      () => secureSessionService.readToken(),
    ).thenAnswer((_) async => 'jwt-token');

    await AuthInterceptor(
      secureSessionService,
      allowedBaseUri: Uri.parse('https://api.example'),
    ).onRequest(requestOptions, handler);

    expect(requestOptions.headers, isNot(contains('Authorization')));
    verify(() => handler.next(requestOptions)).called(1);
  });

  test(
    'refreshes an expired session and retries the original request',
    () async {
      final secureSessionService = MockSecureSessionService();
      final dio = MockDio();
      final refreshClient = MockDio();
      final handler = MockErrorInterceptorHandler();
      final requestOptions = RequestOptions(
        baseUrl: 'https://api.example',
        path: '/api/v1/telemetry/location',
      );
      final expiredError = DioException(
        requestOptions: requestOptions,
        response: Response<Object?>(
          requestOptions: requestOptions,
          statusCode: 401,
        ),
      );

      when(
        () => secureSessionService.readRefreshToken(),
      ).thenAnswer((_) async => 'refresh-token');
      when(
        () => secureSessionService.saveToken(any()),
      ).thenAnswer((_) async {});
      when(
        () => secureSessionService.saveRefreshToken(any()),
      ).thenAnswer((_) async {});
      when(
        () => refreshClient.post<Object?>(
          any(),
          data: any<dynamic>(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<Object?>(
          requestOptions: RequestOptions(path: '/api/v1/auth/refresh'),
          statusCode: 200,
          data: <String, dynamic>{
            'success': true,
            'data': <String, dynamic>{
              'token': 'new-access-token',
              'refreshToken': 'rotated-refresh-token',
            },
          },
        ),
      );
      when(() => dio.fetch<dynamic>(any())).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: requestOptions,
          statusCode: 202,
          data: <String, dynamic>{'success': true},
        ),
      );

      await AuthInterceptor(
        secureSessionService,
        dio: dio,
        refreshClient: refreshClient,
        allowedBaseUri: Uri.parse('https://api.example'),
      ).onError(expiredError, handler);

      verify(
        () => refreshClient.post<Object?>(
          '/api/v1/auth/refresh',
          data: <String, dynamic>{'refreshToken': 'refresh-token'},
          options: any(named: 'options'),
        ),
      ).called(1);
      verify(
        () => secureSessionService.saveToken('new-access-token'),
      ).called(1);
      verify(
        () => secureSessionService.saveRefreshToken('rotated-refresh-token'),
      ).called(1);
      verify(() => dio.fetch<dynamic>(any())).called(1);
      verify(() => handler.resolve(any())).called(1);
      verifyNever(() => handler.next(any()));
    },
  );

  test('clears an expired session without a refresh token', () async {
    final secureSessionService = MockSecureSessionService();
    final dio = MockDio();
    final refreshClient = MockDio();
    final handler = MockErrorInterceptorHandler();
    final requestOptions = RequestOptions(
      baseUrl: 'https://api.example',
      path: '/api/v1/telemetry/location',
    );
    final expiredError = DioException(
      requestOptions: requestOptions,
      response: Response<Object?>(
        requestOptions: requestOptions,
        statusCode: 401,
      ),
    );

    when(
      () => secureSessionService.readRefreshToken(),
    ).thenAnswer((_) async => null);
    when(() => secureSessionService.clearSession()).thenAnswer((_) async {});

    await AuthInterceptor(
      secureSessionService,
      dio: dio,
      refreshClient: refreshClient,
      allowedBaseUri: Uri.parse('https://api.example'),
    ).onError(expiredError, handler);

    verify(() => secureSessionService.clearSession()).called(1);
    verify(() => handler.next(expiredError)).called(1);
    verifyNever(() => dio.fetch<dynamic>(any()));
  });

  test('keeps the session when refresh fails transiently', () async {
    final secureSessionService = MockSecureSessionService();
    final dio = MockDio();
    final refreshClient = MockDio();
    final handler = MockErrorInterceptorHandler();
    final requestOptions = RequestOptions(
      baseUrl: 'https://api.example',
      path: '/api/v1/telemetry/location',
    );
    final expiredError = DioException(
      requestOptions: requestOptions,
      response: Response<Object?>(
        requestOptions: requestOptions,
        statusCode: 401,
      ),
    );

    when(
      () => secureSessionService.readRefreshToken(),
    ).thenAnswer((_) async => 'refresh-token');
    when(
      () => refreshClient.post<Object?>(
        any(),
        data: any<dynamic>(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/api/v1/auth/refresh'),
        type: DioExceptionType.connectionError,
      ),
    );

    await AuthInterceptor(
      secureSessionService,
      dio: dio,
      refreshClient: refreshClient,
      allowedBaseUri: Uri.parse('https://api.example'),
    ).onError(expiredError, handler);

    verifyNever(() => secureSessionService.clearSession());
    verify(() => handler.next(expiredError)).called(1);
    verifyNever(() => dio.fetch<dynamic>(any()));
  });
}
