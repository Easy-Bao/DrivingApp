import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';

class IdempotencyInterceptor extends Interceptor {
  static const _stateChangingMethods = {'POST', 'PUT', 'PATCH', 'DELETE'};
  final Random _random = Random.secure();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final method = options.method.toUpperCase();
    final hasKey = options.headers.keys.any(
      (key) => key.toLowerCase() == 'idempotency-key',
    );
    if (_stateChangingMethods.contains(method) &&
        !hasKey &&
        options.extra['skipIdempotency'] != true) {
      final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
      options.headers['Idempotency-Key'] =
          '${DateTime.now().microsecondsSinceEpoch}-${base64Url.encode(bytes)}';
    }
    handler.next(options);
  }
}
