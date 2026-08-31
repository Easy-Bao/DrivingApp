import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/infrastructure/network/passenger_auth_interceptor.dart';
import 'package:passenger_app/src/infrastructure/session/passenger_session_store.dart';

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

class MockDio extends Mock implements Dio {}

class MockSecureSessionService extends Mock implements PassengerSessionStore {}

class FakeRequestOptions extends Fake implements RequestOptions {}

class FakeResponse extends Fake implements Response<dynamic> {}

class FakeDioException extends Fake implements DioException {}

class TestSecureSessionService extends PassengerSessionStore {
  TestSecureSessionService(this.refreshTokenValue);

  final String? refreshTokenValue;
  bool sessionCleared = false;

  @override
  Future<String?> readRefreshToken() async => refreshTokenValue;

  @override
  Future<void> clearSession() async {
    sessionCleared = true;
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(FakeResponse());
    registerFallbackValue(FakeDioException());
  });

  test('adds the securely stored token to authenticated requests', () async {
    final secureSessionService = MockSecureSessionService();
    final handler = MockRequestInterceptorHandler();
    final requestOptions = RequestOptions(
      path: '/api/v1/passengers/passenger-42',
    );
    when(
      () => secureSessionService.readToken(),
    ).thenAnswer((_) async => 'jwt-token');

    await PassengerAuthInterceptor(
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

    await PassengerAuthInterceptor(
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
        path: '/api/v1/passengers/passenger-42',
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
          statusCode: 200,
          data: <String, dynamic>{'success': true},
        ),
      );

      await PassengerAuthInterceptor(
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

  test(
    'clears an invalid refresh session instead of retrying forever',
    () async {
      final secureSessionService = TestSecureSessionService('refresh-token');
      final dio = MockDio();
      final refreshClient = MockDio();
      final handler = MockErrorInterceptorHandler();
      final requestOptions = RequestOptions(
        baseUrl: 'https://api.example',
        path: '/api/v1/passengers/passenger-42',
      );
      final expiredError = DioException(
        requestOptions: requestOptions,
        response: Response<Object?>(
          requestOptions: requestOptions,
          statusCode: 401,
        ),
      );

      when(
        () => refreshClient.post<Object?>(
          any(),
          data: any<dynamic>(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/auth/refresh'),
          response: Response<Object?>(
            requestOptions: RequestOptions(path: '/api/v1/auth/refresh'),
            statusCode: 401,
          ),
        ),
      );

      await PassengerAuthInterceptor(
        secureSessionService,
        dio: dio,
        refreshClient: refreshClient,
        allowedBaseUri: Uri.parse('https://api.example'),
      ).onError(expiredError, handler);

      expect(secureSessionService.sessionCleared, isTrue);
      verify(() => handler.next(expiredError)).called(1);
      verifyNever(() => dio.fetch<dynamic>(any()));
    },
  );

  test('keeps the session when refresh fails transiently', () async {
    final secureSessionService = TestSecureSessionService('refresh-token');
    final dio = MockDio();
    final refreshClient = MockDio();
    final handler = MockErrorInterceptorHandler();
    final requestOptions = RequestOptions(
      baseUrl: 'https://api.example',
      path: '/api/v1/passengers/passenger-42',
    );
    final expiredError = DioException(
      requestOptions: requestOptions,
      response: Response<Object?>(
        requestOptions: requestOptions,
        statusCode: 401,
      ),
    );

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

    await PassengerAuthInterceptor(
      secureSessionService,
      dio: dio,
      refreshClient: refreshClient,
      allowedBaseUri: Uri.parse('https://api.example'),
    ).onError(expiredError, handler);

    expect(secureSessionService.sessionCleared, isFalse);
    verify(() => handler.next(expiredError)).called(1);
    verifyNever(() => dio.fetch<dynamic>(any()));
  });
}
