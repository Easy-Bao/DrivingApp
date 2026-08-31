import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';

class IdempotencyInterceptor extends Interceptor {
  static const _stateChangingMethods = {'POST', 'PUT', 'PATCH', 'DELETE'};
  static const _fareQueryPaths = {
    '/api/v1/bids/fare',
    '/api/v1/fares/estimate',
    '/api/v1/fares/calculate-final',
  };
  final Random _random = Random.secure();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final method = options.method.toUpperCase();
    final hasKey = options.headers.keys.any(
      (key) => key.toLowerCase() == 'idempotency-key',
    );
    if (_supportsIdempotency(options, method) &&
        !hasKey &&
        options.extra['skipIdempotency'] != true) {
      final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
      options.headers['Idempotency-Key'] =
          '${DateTime.now().microsecondsSinceEpoch}-${base64Url.encode(bytes)}';
    }
    handler.next(options);
  }

  bool _supportsIdempotency(RequestOptions options, String method) {
    if (!_stateChangingMethods.contains(method)) {
      return false;
    }
    final path = options.uri.path;
    if (_hasPathPrefix(path, '/api/v1/auth') ||
        _hasPathPrefix(path, '/api/v1/telemetry') ||
        _hasPathPrefix(path, '/api/v1/location') ||
        _fareQueryPaths.contains(path)) {
      return false;
    }
    if (method == 'POST' &&
        (path == '/api/v1/driver/documents' ||
            (_hasPathPrefix(path, '/api/v1/drivers') &&
                path.endsWith('/online')))) {
      return false;
    }
    return true;
  }

  bool _hasPathPrefix(String path, String prefix) {
    return path == prefix || path.startsWith('$prefix/');
  }
}
