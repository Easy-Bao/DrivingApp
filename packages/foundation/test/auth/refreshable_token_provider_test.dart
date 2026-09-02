import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  test('refreshes an expired access token before transport use', () async {
    final oldToken = _jwt(
      DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
    );
    final newToken = _jwt(
      DateTime.now().toUtc().add(const Duration(minutes: 15)),
    );
    var accessToken = oldToken;
    var storedRefreshToken = 'refresh-1';
    var refreshRequests = 0;

    final refreshClient = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = _ResponseAdapter((options) {
        refreshRequests++;
        expect(options.path, '/api/v1/auth/refresh');
        return ResponseBody.fromString(
          jsonEncode({
            'data': {'token': newToken, 'refreshToken': 'refresh-2'},
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

    final provider = RefreshableTokenProvider(
      readAccessToken: () async => accessToken,
      readRefreshToken: () async => storedRefreshToken,
      saveAccessToken: (value) async => accessToken = value,
      saveRefreshToken: (value) async => storedRefreshToken = value,
      clearSession: () async {},
      refreshClient: refreshClient,
    );

    expect(await provider.getToken(), newToken);
    expect(accessToken, newToken);
    expect(storedRefreshToken, 'refresh-2');
    expect(refreshRequests, 1);
  });

  test('does not refresh a token outside the refresh window', () async {
    final token = _jwt(DateTime.now().toUtc().add(const Duration(minutes: 15)));
    var refreshRequests = 0;
    final refreshClient = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = _ResponseAdapter((_) {
        refreshRequests++;
        return ResponseBody.fromString('{}', 500);
      });

    final provider = RefreshableTokenProvider(
      readAccessToken: () async => token,
      readRefreshToken: () async => 'refresh-1',
      saveAccessToken: (_) async {},
      saveRefreshToken: (_) async {},
      clearSession: () async {},
      refreshClient: refreshClient,
    );

    expect(await provider.getToken(), token);
    expect(refreshRequests, 0);
  });

  test('clears the session when the refresh token is rejected', () async {
    var clearCount = 0;
    final refreshClient = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = _ResponseAdapter((_) {
        return ResponseBody.fromString('Unauthorized', 401);
      });

    final provider = RefreshableTokenProvider(
      readAccessToken: () async => 'expired-token',
      readRefreshToken: () async => 'refresh-1',
      saveAccessToken: (_) async {},
      saveRefreshToken: (_) async {},
      clearSession: () async => clearCount++,
      refreshClient: refreshClient,
    );

    expect(await provider.refreshAccessToken(), isNull);
    expect(clearCount, 1);
  });
}

String _jwt(DateTime expiresAt) {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');

  return '${encode({'alg': 'none', 'typ': 'JWT'})}.${encode({'exp': expiresAt.millisecondsSinceEpoch ~/ 1000})}.signature';
}

final class _ResponseAdapter(this._handler) implements HttpClientAdapter {
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
