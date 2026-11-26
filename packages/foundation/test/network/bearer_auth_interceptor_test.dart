import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

class _RequestHandler extends RequestInterceptorHandler {
  RequestOptions? forwarded;

  @override
  void next(RequestOptions options) => forwarded = options;
}

void main() {
  for (final (origin, expected) in [
    ('https://api.example', true),
    ('https://api.example:443', true),
    ('https://api.example:8443', false),
    ('http://api.example', false),
    ('https://other.example', false),
  ]) {
    test('token origin boundary for $origin', () async {
      var reads = 0;
      final provider = RefreshableTokenProvider(
        readAccessToken: () async {
          reads++;
          return 'access-token';
        },
        readRefreshToken: () async => null,
        saveAccessToken: (_) async {},
        saveRefreshToken: (_) async {},
        clearSession: () async {},
      );
      final interceptor = BearerAuthInterceptor(
        tokenProvider: provider,
        allowedBaseUri: Uri.parse('https://api.example'),
      );
      final request = RequestOptions(baseUrl: origin, path: '/private');
      final handler = _RequestHandler();
      await interceptor.onRequest(request, handler);
      expect(
        request.headers['Authorization'],
        expected ? 'Bearer access-token' : isNull,
      );
      expect(reads, expected ? 1 : 0);
      expect(handler.forwarded, same(request));
    });
  }

  test('explicit public requests do not read session credentials', () async {
    var reads = 0;
    final provider = RefreshableTokenProvider(
      readAccessToken: () async {
        reads++;
        return 'access-token';
      },
      readRefreshToken: () async => null,
      saveAccessToken: (_) async {},
      saveRefreshToken: (_) async {},
      clearSession: () async {},
    );
    final request = RequestOptions(
      path: '/public',
      extra: {'skipAuthToken': true},
    );
    await BearerAuthInterceptor(tokenProvider: provider)
        .onRequest(request, _RequestHandler());
    expect(reads, 0);
    expect(request.headers, isNot(contains('Authorization')));
  });

  test('refreshes once on 401 and retries with rotated token', () async {
    var accessToken = 'expired-token';
    var refreshToken = 'refresh-1';
    var refreshCalls = 0;
    var apiCalls = 0;

    final refreshClient = Dio(BaseOptions(baseUrl: 'https://api.example'))
      ..httpClientAdapter = _FnAdapter((options) {
        refreshCalls++;
        return ResponseBody.fromString(
          '{"data":{"token":"fresh-token","refreshToken":"refresh-2"}}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

    final provider = RefreshableTokenProvider(
      readAccessToken: () async => accessToken,
      readRefreshToken: () async => refreshToken,
      saveAccessToken: (value) async => accessToken = value,
      saveRefreshToken: (value) async => refreshToken = value,
      clearSession: () async {},
      refreshClient: refreshClient,
    );

    final dio = Dio(BaseOptions(baseUrl: 'https://api.example'))
      ..httpClientAdapter = _FnAdapter((options) {
        apiCalls++;
        if (options.headers['Authorization'] == 'Bearer fresh-token') {
          return ResponseBody.fromString('{"ok":true}', 200);
        }
        return ResponseBody.fromString('Unauthorized', 401);
      });
    dio.interceptors.add(
      BearerAuthInterceptor(
        tokenProvider: provider,
        dio: dio,
        allowedBaseUri: Uri.parse('https://api.example'),
      ),
    );
    addTearDown(() {
      dio.close(force: true);
      refreshClient.close(force: true);
    });

    final response = await dio.get<String>('/api/v1/rides');
    expect(response.statusCode, 200);
    expect(apiCalls, 2);
    expect(refreshCalls, 1);
  });

  test('reuses newly rotated token without triggering duplicate refresh on concurrent 401', () async {
    var refreshCalls = 0;
    var apiCalls = 0;
    final refreshClient = Dio(BaseOptions(baseUrl: 'https://api.example'))
      ..httpClientAdapter = _FnAdapter((_) {
        refreshCalls++;
        return ResponseBody.fromString('Unauthorized', 401);
      });

    final provider = RefreshableTokenProvider(
      readAccessToken: () async => 'already-rotated-token',
      readRefreshToken: () async => 'refresh-1',
      saveAccessToken: (_) async {},
      saveRefreshToken: (_) async {},
      clearSession: () async {},
      refreshClient: refreshClient,
    );

    final dio = Dio(BaseOptions(baseUrl: 'https://api.example'))
      ..httpClientAdapter = _FnAdapter((options) {
        apiCalls++;
        if (options.headers['Authorization'] ==
            'Bearer already-rotated-token') {
          return ResponseBody.fromString('{"ok":true}', 200);
        }
        return ResponseBody.fromString('Unauthorized', 401);
      });
    final interceptor = BearerAuthInterceptor(
      tokenProvider: provider,
      dio: dio,
      allowedBaseUri: Uri.parse('https://api.example'),
    );
    addTearDown(() {
      dio.close(force: true);
      refreshClient.close(force: true);
    });

    final failedOptions = RequestOptions(
      baseUrl: 'https://api.example',
      path: '/api/v1/rides',
      headers: {'Authorization': 'Bearer stale-token'},
    );
    final errorHandler = _ErrorHandler();
    await interceptor.onError(
      DioException.badResponse(
        statusCode: 401,
        requestOptions: failedOptions,
        response: Response<dynamic>(
          requestOptions: failedOptions,
          statusCode: 401,
        ),
      ),
      errorHandler,
    );

    expect(errorHandler.resolved?.statusCode, 200);
    expect(apiCalls, 1);
    expect(refreshCalls, 0);
  });

  test('clears session and notifies onSessionExpired when refresh token is missing', () async {
    final store = _MemorySessionTokenStore(accessToken: 'expired-token');
    var expiredNotified = false;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example'));
    final refreshClient = Dio(BaseOptions(baseUrl: 'https://api.example'));
    addTearDown(() {
      dio.close(force: true);
      refreshClient.close(force: true);
    });

    final interceptor = ApiClientFactory.createAuthInterceptor(
      sessionStore: store,
      dio: dio,
      refreshClient: refreshClient,
      allowedBaseUri: Uri.parse('https://api.example'),
      onSessionExpired: () => expiredNotified = true,
    );
    final requestOptions = RequestOptions(
      baseUrl: 'https://api.example',
      path: '/api/v1/rides',
    );
    final error = DioException.badResponse(
      statusCode: 401,
      requestOptions: requestOptions,
      response: Response<dynamic>(
        requestOptions: requestOptions,
        statusCode: 401,
      ),
    );
    final handler = _ErrorHandler();

    await interceptor.onError(error, handler);

    expect(store.cleared, isTrue);
    expect(expiredNotified, isTrue);
    expect(handler.forwarded, same(error));
  });

  test(
    'clears session when refresh endpoint rejects the refresh token with 401',
    () async {
      final store = _MemorySessionTokenStore(
        accessToken: 'expired-token',
        refreshToken: 'revoked-refresh-token',
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example'));
      final refreshClient = Dio(BaseOptions(baseUrl: 'https://api.example'))
        ..httpClientAdapter = _FnAdapter((_) {
          return ResponseBody.fromString('Unauthorized', 401);
        });
      addTearDown(() {
        dio.close(force: true);
        refreshClient.close(force: true);
      });

      final interceptor = ApiClientFactory.createAuthInterceptor(
        sessionStore: store,
        dio: dio,
        refreshClient: refreshClient,
        allowedBaseUri: Uri.parse('https://api.example'),
      );
      final requestOptions = RequestOptions(
        baseUrl: 'https://api.example',
        path: '/api/v1/rides',
      );
      final error = DioException.badResponse(
        statusCode: 401,
        requestOptions: requestOptions,
        response: Response<dynamic>(
          requestOptions: requestOptions,
          statusCode: 401,
        ),
      );
      final handler = _ErrorHandler();

      await interceptor.onError(error, handler);

      expect(store.cleared, isTrue);
      expect(handler.forwarded, same(error));
    },
  );

  test('preserves session when refresh fails transiently', () async {
    final store = _MemorySessionTokenStore(
      accessToken: 'expired-token',
      refreshToken: 'valid-refresh-token',
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example'));
    final refreshClient = Dio(BaseOptions(baseUrl: 'https://api.example'))
      ..httpClientAdapter = _FnAdapter((options) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });
    addTearDown(() {
      dio.close(force: true);
      refreshClient.close(force: true);
    });

    final interceptor = ApiClientFactory.createAuthInterceptor(
      sessionStore: store,
      dio: dio,
      refreshClient: refreshClient,
      allowedBaseUri: Uri.parse('https://api.example'),
    );
    final requestOptions = RequestOptions(
      baseUrl: 'https://api.example',
      path: '/api/v1/rides',
    );
    final error = DioException.badResponse(
      statusCode: 401,
      requestOptions: requestOptions,
      response: Response<dynamic>(
        requestOptions: requestOptions,
        statusCode: 401,
      ),
    );
    final handler = _ErrorHandler();

    await interceptor.onError(error, handler);

    expect(store.cleared, isFalse);
    expect(handler.forwarded, same(error));
  });
}

final class _MemorySessionTokenStore implements SessionTokenStore {
  _MemorySessionTokenStore({this.accessToken, this.refreshToken});

  String? accessToken;
  String? refreshToken;
  bool cleared = false;

  @override
  Future<String?> readToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveToken(String token) async => accessToken = token;

  @override
  Future<void> saveRefreshToken(String token) async => refreshToken = token;

  @override
  Future<void> clearSession() async {
    cleared = true;
    accessToken = null;
    refreshToken = null;
  }
}

final class _ErrorHandler extends ErrorInterceptorHandler {
  Response<dynamic>? resolved;
  DioException? forwarded;

  @override
  void resolve(Response<dynamic> response) => resolved = response;

  @override
  void next(DioException err) => forwarded = err;
}

final class _FnAdapter(this._handler) implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => _handler(options);

  @override
  void close({bool force = false}) {}
}
