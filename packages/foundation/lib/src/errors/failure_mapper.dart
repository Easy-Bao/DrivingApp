import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:foundation/src/errors/exceptions.dart';
import 'package:foundation/src/errors/failures.dart';

const _defaultServerMessage =
    'Something went wrong. Try again.';
const _defaultValidationMessage =
    'Check the highlighted fields.';
const _defaultNetworkMessage =
    "Couldn't connect. Check your internet connection and try again.";
const _defaultTimeoutMessage =
    'The request took too long. Try again.';
const _defaultCacheMessage =
    'Saved information is unavailable. Try again.';

/// Converts transport and storage exceptions into safe domain failures.
///
/// Data sources may contain backend-provided details, but those details must
/// stay in technical logs. Repositories use this mapper before a failure can
/// cross into a BLoC or view.
class FailureMapper._() {
  static Failure fromException(
    Object error, {
    String serverMessage = _defaultServerMessage,
    String validationMessage = _defaultValidationMessage,
    String networkMessage = _defaultNetworkMessage,
    String timeoutMessage = _defaultTimeoutMessage,
    String cacheMessage = _defaultCacheMessage,
  }) {
    Failure mapStatus(int? statusCode) => _fromStatusCode(
      statusCode,
      serverMessage: serverMessage,
      validationMessage: validationMessage,
      networkMessage: networkMessage,
      timeoutMessage: timeoutMessage,
    );

    return switch (error) {
      NetworkFailure() || SocketException() => NetworkFailure(networkMessage),
      NetworkCircuitOpenException() => NetworkFailure(networkMessage),
      CacheFailure() || CacheException() => CacheFailure(cacheMessage),
      ValidationFailure() => ValidationFailure(validationMessage),
      final ServerFailure failure => mapStatus(failure.statusCode),
      final DioException dioError => _fromDioException(
        dioError,
        mapStatus: mapStatus,
        networkMessage: networkMessage,
        timeoutMessage: timeoutMessage,
      ),
      ServerException(statusCode: 0) => NetworkFailure(networkMessage),
      final ServerException exception => mapStatus(exception.statusCode),
      TimeoutException() => ServerFailure.withStatusCode(timeoutMessage, 504),
      DataParsingException() ||
      FormatException() => ServerFailure(serverMessage),
      final Failure failure => failure,
      _ => ServerFailure(serverMessage),
    };
  }

  static Failure _fromDioException(
    DioException error, {
    required Failure Function(int? statusCode) mapStatus,
    required String networkMessage,
    required String timeoutMessage,
  }) {
    final statusCode = error.response?.statusCode;
    if (statusCode == null && _isTimeout(error)) {
      return ServerFailure.withStatusCode(timeoutMessage, 504);
    }
    if (statusCode == null && _isOffline(error)) {
      return NetworkFailure(networkMessage);
    }
    return mapStatus(statusCode);
  }

  static Failure _fromStatusCode(
    int? statusCode, {
    required String serverMessage,
    required String validationMessage,
    required String networkMessage,
    required String timeoutMessage,
  }) {
    if (statusCode == null || statusCode == 0) {
      return NetworkFailure(networkMessage);
    }

    return switch (statusCode) {
      401 => const ServerFailure.withStatusCode(
        'Your session has expired. Sign in again.',
        401,
      ),
      403 => const ServerFailure.withStatusCode(
        "You don't have permission to do that.",
        403,
      ),
      400 || 422 => ValidationFailure(validationMessage),
      429 => const ServerFailure.withStatusCode(
        'Too many requests. Wait a moment and try again.',
        429,
      ),
      503 => const ServerFailure.withStatusCode(
        'The service is unavailable. Try again later.',
        503,
      ),
      504 => ServerFailure.withStatusCode(timeoutMessage, 504),
      >= 500 => ServerFailure.withStatusCode(serverMessage, statusCode),
      _ => ServerFailure.withStatusCode(serverMessage, statusCode),
    };
  }

  static bool _isTimeout(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => true,
      _ => false,
    };
  }

  static bool _isOffline(DioException error) {
    return error.error is SocketException ||
        error.type == DioExceptionType.connectionError && error.error == null;
  }
}
