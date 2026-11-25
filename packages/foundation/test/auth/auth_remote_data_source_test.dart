import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  test(
    'postData unwraps success envelope and rejects invalid bodies',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = _AuthAdapter((options) {
          if (options.path == '/ok') {
            return ResponseBody.fromString(
              jsonEncode({
                'success': true,
                'data': {'token': 'abc'},
              }),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          }
          return ResponseBody.fromString(
            jsonEncode({'success': false, 'data': null}),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });
      addTearDown(() => dio.close(force: true));

      final dataSource = AuthRemoteDataSourceImpl(dio);
      expect(await dataSource.postData('/ok', requestBody: const {}), {
        'token': 'abc',
      });
      await expectLater(
        dataSource.postData('/bad', requestBody: const {}),
        throwsA(isA<DataParsingException>()),
      );
    },
  );

  test('postJson maps network errors without leaking dev copy', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = _AuthAdapter((options) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      });
    addTearDown(() => dio.close(force: true));

    final dataSource = AuthRemoteDataSourceImpl(dio);
    await expectLater(
      dataSource.postJson('/login', requestBody: const {}),
      throwsA(
        isA<ServerException>().having(
          (e) => e.message,
          'message',
          isNot(contains('local services')),
        ),
      ),
    );
  });
}

final class _AuthAdapter(this._handler) implements HttpClientAdapter {
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
