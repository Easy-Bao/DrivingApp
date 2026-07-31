import 'dart:math';

import 'package:core_models/core_models.dart';
import 'package:dio/dio.dart';

class DriverOperationsClient {
  DriverOperationsClient({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Map<String, dynamic>> getOperatingStatus() => _getMap('/drivers/me');

  Future<Map<String, dynamic>> setOnline({
    required bool isOnline,
    double? lat,
    double? lng,
  }) async {
    final response = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/drivers/me/online',
        data: {'isOnline': isOnline, 'lat': lat, 'lng': lng},
      ),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> getWallet() => _getMap('/drivers/me/credits');

  Future<Map<String, dynamic>> getLedger({int page = 1, int limit = 25}) =>
      _getMap(
        '/drivers/me/credits/ledger',
        queryParameters: {'page': page, 'limit': limit},
      );

  Future<List<Map<String, dynamic>>> getTopupChannels() async {
    final response = await _request(
      () => _dio.get<List<dynamic>>('/drivers/me/topup-channels'),
    );
    return (response.data ?? const <dynamic>[])
        .whereType<Map>()
        .map(_asMap)
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> submitTopup({
    required String channelId,
    required int amountCentavos,
    required String senderName,
    required String transactionReference,
  }) async {
    final response = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '/drivers/me/topups',
        options: Options(headers: {'Idempotency-Key': _newIdempotencyKey()}),
        data: {
          'channelId': channelId,
          'amountCentavos': amountCentavos,
          'senderName': senderName,
          'transactionReference': transactionReference,
        },
      ),
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> getTopups({int page = 1, int limit = 25}) =>
      _getMap(
        '/drivers/me/topups',
        queryParameters: {'page': page, 'limit': limit},
      );

  Future<Map<String, dynamic>> _getMap(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _request(
      () => _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      ),
    );
    return _asMap(response.data);
  }

  Future<Response<T>> _request<T>(
    Future<Response<T>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      final data = error.response?.data;
      final body = data is Map ? data : const <String, dynamic>{};
      throw DriverOperationException(
        code: body['code']?.toString(),
        message:
            body['message']?.toString() ??
            body['error']?.toString() ??
            'Unable to reach the driver service.',
        statusCode: error.response?.statusCode,
      );
    }
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    throw DataParsingException(message: 'Expected an object response.');
  }

  static String _newIdempotencyKey() {
    final random = Random.secure().nextInt(1 << 32).toRadixString(16);
    return 'driver-topup-${DateTime.now().microsecondsSinceEpoch}-$random';
  }
}

class DriverOperationException implements Exception {
  const DriverOperationException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  final String? code;
  final String message;
  final int? statusCode;

  @override
  String toString() => code == null ? message : '$code: $message';
}

String driverOperationMessage(Object error) {
  final rawCode = switch (error) {
    DriverOperationException(:final code) => code,
    ServerException(:final message) => message,
    _ => error.toString(),
  };
  final code = (rawCode ?? '').toUpperCase();

  if (code.contains('DRIVER_NOT_APPROVED')) {
    return 'Your driver account is not approved. Contact support before going online or accepting rides.';
  }
  if (code.contains('DOCUMENTS_EXPIRED')) {
    return 'One or more required documents have expired. Contact support to submit updated documents.';
  }
  if (code.contains('DOCUMENTS_INCOMPLETE') ||
      code.contains('DRIVER_DOCUMENTS_INCOMPLETE')) {
    return 'Required driver documents are incomplete, rejected, or expired. Contact support before going online or accepting rides.';
  }
  if (code.contains('ACCOUNT_RESTRICTED')) {
    return 'Your account is restricted. You can still view credits and history; contact support for the reason.';
  }
  if (code.contains('INSUFFICIENT_CREDIT')) {
    return 'Your available service credits cannot cover this ride commission. Top up before accepting.';
  }

  return switch (error) {
    DriverOperationException(:final message) => message,
    ServerException(:final message) => message,
    _ => 'Something went wrong. Please try again.',
  };
}
