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
}
