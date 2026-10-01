import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:foundation/src/errors/exceptions.dart';

enum NetworkErrorCategory {
  connectionRefused,
  connectionTimeout,
  sendTimeout,
  receiveTimeout,
  requestTimeout,
  dnsFailure,
  hostUnreachable,
  deviceOffline,
  tlsFailure,
  requestCancelled,
  invalidServerResponse,
  invalidJson,
  httpClientError,
  unauthorized,
  forbidden,
  notFound,
  rateLimited,
  serverError,
  connectionError,
  unknown,
}

/// Safe, structured diagnostics for transport failures.
///
/// The category is intended for development logs and telemetry correlation.
/// It deliberately contains no request URL, headers, response body, or socket
/// text, so adding it to the shared logging boundary cannot expose credentials
/// or backend details.
final class NetworkErrorDiagnostic {
  const NetworkErrorDiagnostic({required this.category, this.statusCode});

  final NetworkErrorCategory category;
  final int? statusCode;

  String get label {
    final name = switch (category) {
      NetworkErrorCategory.connectionRefused => 'connection_refused',
      NetworkErrorCategory.connectionTimeout => 'connection_timeout',
      NetworkErrorCategory.sendTimeout => 'send_timeout',
      NetworkErrorCategory.receiveTimeout => 'receive_timeout',
      NetworkErrorCategory.requestTimeout => 'request_timeout',
      NetworkErrorCategory.dnsFailure => 'dns_failure',
      NetworkErrorCategory.hostUnreachable => 'host_unreachable',
      NetworkErrorCategory.deviceOffline => 'device_offline',
      NetworkErrorCategory.tlsFailure => 'tls_failure',
      NetworkErrorCategory.requestCancelled => 'request_cancelled',
      NetworkErrorCategory.invalidServerResponse => 'invalid_server_response',
      NetworkErrorCategory.invalidJson => 'invalid_json',
      NetworkErrorCategory.httpClientError => 'http_client_error',
      NetworkErrorCategory.unauthorized => 'http_unauthorized',
      NetworkErrorCategory.forbidden => 'http_forbidden',
      NetworkErrorCategory.notFound => 'http_not_found',
      NetworkErrorCategory.rateLimited => 'http_rate_limited',
      NetworkErrorCategory.serverError => 'http_server_error',
      NetworkErrorCategory.connectionError => 'connection_error',
      NetworkErrorCategory.unknown => 'unknown',
    };
    return statusCode == null ? name : '$name($statusCode)';
  }

  factory NetworkErrorDiagnostic.fromError(Object error) {
    if (error is DioException) return _fromDioException(error);
    if (error is SocketException) return _fromSocketException(error);
    if (error is HandshakeException) {
      return const NetworkErrorDiagnostic(
        category: NetworkErrorCategory.tlsFailure,
      );
    }
    if (error is DataParsingException) {
      return const NetworkErrorDiagnostic(
        category: NetworkErrorCategory.invalidJson,
      );
    }
    if (error is FormatException) {
      return const NetworkErrorDiagnostic(
        category: NetworkErrorCategory.invalidServerResponse,
      );
    }
    if (error is TimeoutException) {
      return const NetworkErrorDiagnostic(
        category: NetworkErrorCategory.requestTimeout,
      );
    }
    if (error is NetworkCircuitOpenException) {
      return const NetworkErrorDiagnostic(
        category: NetworkErrorCategory.deviceOffline,
      );
    }
    return const NetworkErrorDiagnostic(category: NetworkErrorCategory.unknown);
  }

  static NetworkErrorDiagnostic _fromDioException(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode != null) return _fromStatusCode(statusCode);

    final underlyingError = error.error;
    if (underlyingError != null) {
      final underlying = NetworkErrorDiagnostic.fromError(underlyingError);
      if (underlying.category != NetworkErrorCategory.unknown) {
        return underlying;
      }
    }

    final category = switch (error.type) {
      DioExceptionType.connectionTimeout =>
        NetworkErrorCategory.connectionTimeout,
      DioExceptionType.sendTimeout => NetworkErrorCategory.sendTimeout,
      DioExceptionType.receiveTimeout => NetworkErrorCategory.receiveTimeout,
      DioExceptionType.transformTimeout => NetworkErrorCategory.requestTimeout,
      DioExceptionType.cancel => NetworkErrorCategory.requestCancelled,
      DioExceptionType.badCertificate => NetworkErrorCategory.tlsFailure,
      DioExceptionType.badResponse =>
        NetworkErrorCategory.invalidServerResponse,
      DioExceptionType.connectionError => NetworkErrorCategory.connectionError,
      DioExceptionType.unknown => NetworkErrorCategory.unknown,
    };
    return NetworkErrorDiagnostic(category: category);
  }

  static NetworkErrorDiagnostic _fromStatusCode(int statusCode) {
    final category = switch (statusCode) {
      401 => NetworkErrorCategory.unauthorized,
      403 => NetworkErrorCategory.forbidden,
      404 => NetworkErrorCategory.notFound,
      429 => NetworkErrorCategory.rateLimited,
      >= 400 && < 500 => NetworkErrorCategory.httpClientError,
      >= 500 => NetworkErrorCategory.serverError,
      _ => NetworkErrorCategory.invalidServerResponse,
    };
    return NetworkErrorDiagnostic(category: category, statusCode: statusCode);
  }

  static NetworkErrorDiagnostic _fromSocketException(SocketException error) {
    final detail = error.message.toLowerCase();
    final errorCode = error.osError?.errorCode;
    if (detail.contains('failed host lookup') ||
        detail.contains('name or service not known') ||
        detail.contains('nodename nor servname')) {
      return const NetworkErrorDiagnostic(
        category: NetworkErrorCategory.dnsFailure,
      );
    }
    if (errorCode == 111 || detail.contains('connection refused')) {
      return const NetworkErrorDiagnostic(
        category: NetworkErrorCategory.connectionRefused,
      );
    }
    if (errorCode == 113 || detail.contains('host is unreachable')) {
      return const NetworkErrorDiagnostic(
        category: NetworkErrorCategory.hostUnreachable,
      );
    }
    if (errorCode == 101 ||
        detail.contains('network is unreachable') ||
        detail.contains('network is down')) {
      return const NetworkErrorDiagnostic(
        category: NetworkErrorCategory.deviceOffline,
      );
    }
    return const NetworkErrorDiagnostic(
      category: NetworkErrorCategory.connectionError,
    );
  }
}
