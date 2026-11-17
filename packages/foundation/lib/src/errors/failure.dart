import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:foundation/src/errors/exceptions.dart';
import 'package:foundation/src/errors/network_diagnostic.dart';

enum ErrorType {
  network,
  server,
  unauthorized,
  validation,
  location,
  configuration,
  unknown,
}

enum NetworkFailureReason {
  serverUnreachable,
  offline,
  dnsLookup,
  tlsHandshake,
  connectionInterrupted,
}

/// [technicalLog] and [stackTrace] are intentionally kept separate from the
/// user copy. They are available to an internal logger and must never be
/// rendered by a widget.
class AppFailure {
  const AppFailure({
    required this.userMessage,
    required this.type,
    this.title,
    this.actionText,
    this.technicalLog,
    this.stackTrace,
  });

  final String? title;
  final String userMessage;
  final String? actionText;
  final ErrorType type;
  final Object? technicalLog;
  final StackTrace? stackTrace;

  factory AppFailure.fromException(Object error, [StackTrace? stackTrace]) {
    _logTechnicalError(error, stackTrace);

    AppFailure createFailure({
      required ErrorType type,
      required String userMessage,
      String? title,
      String? actionText,
    }) {
      return AppFailure(
        title: title,
        userMessage: userMessage,
        actionText: actionText,
        type: type,
        technicalLog: error,
        stackTrace: stackTrace,
      );
    }

    if (error is ConfigurationException) {
      return createFailure(
        title: 'App configuration error',
        userMessage: error.message,
        type: ErrorType.configuration,
      );
    }

    if (error is NetworkFailure) {
      return _fromNetworkReason(error.reason, createFailure);
    }

    final statusCode = _statusCodeFor(error);
    if (statusCode != null) {
      return _fromStatusCode(statusCode, createFailure);
    }

    final diagnostic = NetworkErrorDiagnostic.fromError(error);
    final diagnosticFailure = _fromDiagnostic(
      diagnostic.category,
      createFailure,
    );
    if (diagnosticFailure != null) {
      return diagnosticFailure;
    }

    if (error is ValidationFailure) {
      return createFailure(
        title: 'Invalid input',
        userMessage: 'Check the highlighted fields.',
        actionText: 'Review',
        type: ErrorType.validation,
      );
    }

    if (error is CacheFailure || error is CacheException) {
      return createFailure(
        title: 'Saved information unavailable',
        userMessage: 'Saved information is unavailable. Try again.',
        actionText: 'Retry',
        type: ErrorType.unknown,
      );
    }

    if (error is ServerFailure) {
      return createFailure(
        title: 'Server error',
        userMessage: 'The server could not complete your request. Try again.',
        actionText: 'Retry',
        type: ErrorType.server,
      );
    }

    if (error is UnexpectedFailure) {
      return createFailure(
        title: 'Unexpected error',
        userMessage: error.message,
        actionText: 'Retry',
        type: ErrorType.unknown,
      );
    }

    if (error is Failure) {
      return createFailure(userMessage: error.message, type: ErrorType.unknown);
    }

    return createFailure(
      title: 'Unexpected error',
      userMessage: 'An unexpected error occurred. Try again.',
      actionText: 'Retry',
      type: ErrorType.unknown,
    );
  }

  static AppFailure? _fromDiagnostic(
    NetworkErrorCategory category,
    AppFailure Function({
      required ErrorType type,
      required String userMessage,
      String? title,
      String? actionText,
    })
    createFailure,
  ) {
    final mapped = mapDiagnosticCategoryToFailure(category);
    if (mapped == null) return null;
    if (mapped is NetworkFailure) {
      return _fromNetworkReason(mapped.reason, createFailure);
    }
    if (mapped is ServerFailure && mapped.statusCode != null) {
      return _fromStatusCode(mapped.statusCode!, createFailure);
    }
    if (category == NetworkErrorCategory.invalidJson) {
      return createFailure(
        title: 'Invalid server response',
        userMessage: mapped.message,
        actionText: 'Retry',
        type: ErrorType.server,
      );
    }
    if (category == NetworkErrorCategory.invalidServerResponse) {
      return createFailure(
        title: 'Invalid response format',
        userMessage: mapped.message,
        actionText: 'Retry',
        type: ErrorType.server,
      );
    }
    if (category == NetworkErrorCategory.requestCancelled) {
      return createFailure(
        title: 'Request cancelled',
        userMessage: mapped.message,
        actionText: 'Retry',
        type: ErrorType.unknown,
      );
    }
    return null;
  }

  static AppFailure _fromNetworkReason(
    NetworkFailureReason reason,
    AppFailure Function({
      required ErrorType type,
      required String userMessage,
      String? title,
      String? actionText,
    })
    createFailure,
  ) {
    return switch (reason) {
      NetworkFailureReason.serverUnreachable => createFailure(
        title: 'Server unreachable',
        userMessage: 'Cannot reach the server. Check that the server is running and try again.',
        actionText: 'Retry',
        type: ErrorType.network,
      ),
      NetworkFailureReason.offline => createFailure(
        title: 'No internet connection',
        userMessage:
            "Couldn't connect. Check your internet connection and try again.",
        actionText: 'Retry',
        type: ErrorType.network,
      ),
      NetworkFailureReason.dnsLookup => createFailure(
        title: 'Server address unavailable',
        userMessage: 'Could not find the server address. Check your internet connection and try again.',
        actionText: 'Retry',
        type: ErrorType.network,
      ),
      NetworkFailureReason.tlsHandshake => createFailure(
        title: 'Secure connection failed',
        userMessage: 'Could not verify a secure server connection. Check your network or device clock and try again.',
        actionText: 'Retry',
        type: ErrorType.network,
      ),
      NetworkFailureReason.connectionInterrupted => createFailure(
        title: 'Connection interrupted',
        userMessage: 'The connection to the server was interrupted. Try again.',
        actionText: 'Retry',
        type: ErrorType.network,
      ),
    };
  }

  static AppFailure _fromStatusCode(
    int statusCode,
    AppFailure Function({
      required ErrorType type,
      required String userMessage,
      String? title,
      String? actionText,
    })
    createFailure,
  ) {
    final description = describeHttpStatusFailure(statusCode);
    return createFailure(
      title: description.title,
      userMessage: description.userMessage,
      actionText: description.actionText,
      type: description.type,
    );
  }

  static int? _statusCodeFor(Object error) {
    if (error is DioException) return error.response?.statusCode;
    if (error is ServerException) {
      return error.statusCode == 0 ? null : error.statusCode;
    }
    if (error is ServerFailure) return error.statusCode;
    return null;
  }

  static void _logTechnicalError(Object error, StackTrace? stackTrace) {
    final diagnostic = NetworkErrorDiagnostic.fromError(error);
    developer.log(
      'Client error mapped to a safe user message: '
      'category=${diagnostic.label}.',
      name: 'shared-error-handler',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

abstract class Failure implements Exception {
  const Failure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message =
        "Couldn't connect. Check your internet connection and try again.",
    this.reason = NetworkFailureReason.offline,
  ]);

  const NetworkFailure.serverUnreachable([
    super.message = 'Cannot reach the server. Check that the server is running and try again.',
  ]) : reason = NetworkFailureReason.serverUnreachable;

  const NetworkFailure.offline([
    super.message =
        "Couldn't connect. Check your internet connection and try again.",
  ]) : reason = NetworkFailureReason.offline;

  const NetworkFailure.dnsLookup([
    super.message = 'Could not find the server address. Check your internet connection and try again.',
  ]) : reason = NetworkFailureReason.dnsLookup;

  const NetworkFailure.tlsHandshake([
    super.message = 'Could not verify a secure server connection. Check your network or device clock and try again.',
  ]) : reason = NetworkFailureReason.tlsHandshake;

  const NetworkFailure.connectionInterrupted([
    super.message = 'The connection to the server was interrupted. Try again.',
  ]) : reason = NetworkFailureReason.connectionInterrupted;

  final NetworkFailureReason reason;
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Check the highlighted fields.']);
}

class CacheFailure extends Failure {
  const CacheFailure([
    super.message = 'Saved information is unavailable. Try again.',
  ]);
}

class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'The server could not complete your request. Try again.',
    this.statusCode,
  ]);

  const factory ServerFailure.withStatusCode(String message, int statusCode) =
      ServerFailure._withStatusCode;

  const ServerFailure._withStatusCode(String message, int statusCode)
    : this(message, statusCode);

  final int? statusCode;
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([
    super.message = 'An unexpected error occurred. Try again.',
  ]);
}

/// Describes an HTTP status code using the shared client-safe copy table.
({String title, String userMessage, String? actionText, ErrorType type})
describeHttpStatusFailure(int statusCode) => switch (statusCode) {
  401 => (
    title: 'Session expired',
    userMessage: 'Your session has expired. Sign in again.',
    actionText: 'Sign in',
    type: ErrorType.unauthorized,
  ),
  403 => (
    title: 'Access restricted',
    userMessage: "You don't have permission to do that.",
    actionText: 'Go back',
    type: ErrorType.unauthorized,
  ),
  400 || 422 => (
    title: 'Invalid request',
    userMessage: 'Check the highlighted fields.',
    actionText: 'Review',
    type: ErrorType.validation,
  ),
  404 => (
    title: 'Not found',
    userMessage: 'The requested item was not found on the server.',
    actionText: 'Retry',
    type: ErrorType.server,
  ),
  408 => (
    title: 'Request timed out',
    userMessage: 'The request took too long. Try again.',
    actionText: 'Retry',
    type: ErrorType.server,
  ),
  409 => (
    title: 'Request conflict',
    userMessage:
        'This information changed on the server. Refresh and try again.',
    actionText: 'Refresh',
    type: ErrorType.validation,
  ),
  429 => (
    title: 'Too many requests',
    userMessage: 'Too many requests. Wait a moment and try again.',
    actionText: null,
    type: ErrorType.server,
  ),
  502 => (
    title: 'Bad gateway',
    userMessage:
        'The server received an invalid response upstream. Try again later.',
    actionText: 'Retry',
    type: ErrorType.server,
  ),
  503 => (
    title: 'Service unavailable',
    userMessage: 'The service is unavailable. Try again later.',
    actionText: 'Retry',
    type: ErrorType.server,
  ),
  504 => (
    title: 'Request timed out',
    userMessage: 'The request took too long. Try again.',
    actionText: 'Retry',
    type: ErrorType.server,
  ),
  >= 500 => (
    title: 'Server error',
    userMessage: 'The server encountered an error. Try again later.',
    actionText: 'Retry',
    type: ErrorType.server,
  ),
  _ => (
    title: 'Request failed',
    userMessage: 'The server could not process this request. Try again.',
    actionText: 'Retry',
    type: ErrorType.unknown,
  ),
};

/// Maps a [NetworkErrorCategory] to its typed [Failure] so `AppFailure` and
/// `FailureMapper` keep one consistent error classification table.
Failure? mapDiagnosticCategoryToFailure(
  NetworkErrorCategory category, {
  String? offlineMessage,
  String timeoutMessage = 'The request took too long. Try again.',
}) {
  return switch (category) {
    NetworkErrorCategory.connectionRefused ||
    NetworkErrorCategory.hostUnreachable =>
      const NetworkFailure.serverUnreachable(),
    NetworkErrorCategory.deviceOffline => NetworkFailure.offline(
      offlineMessage ??
          "Couldn't connect. Check your internet connection and try again.",
    ),
    NetworkErrorCategory.dnsFailure => const NetworkFailure.dnsLookup(),
    NetworkErrorCategory.tlsFailure => const NetworkFailure.tlsHandshake(),
    NetworkErrorCategory.connectionError =>
      const NetworkFailure.connectionInterrupted(),
    NetworkErrorCategory.connectionTimeout ||
    NetworkErrorCategory.sendTimeout ||
    NetworkErrorCategory.receiveTimeout ||
    NetworkErrorCategory.requestTimeout => ServerFailure.withStatusCode(
      timeoutMessage,
      504,
    ),
    NetworkErrorCategory.requestCancelled => const UnexpectedFailure(
      'The request was cancelled before completing. Try again.',
    ),
    NetworkErrorCategory.invalidJson => const ServerFailure(
      'Received an unexpected response format. Try again.',
    ),
    NetworkErrorCategory.invalidServerResponse => const ServerFailure(
      'Received an unreadable response from the server. Try again.',
    ),
    _ => null,
  };
}
