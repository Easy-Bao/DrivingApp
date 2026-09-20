import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:foundation/src/errors/exceptions.dart';
import 'package:foundation/src/errors/failures.dart';

enum ErrorType { network, server, unauthorized, validation, location, unknown }

/// Presentation-safe error data produced at the client boundary.
///
/// [technicalLog] and [stackTrace] are intentionally kept separate from the
/// user copy. They are available to an internal logger and must never be
/// rendered by a widget.
class const AppFailure({
  required this.userMessage,
  required this.type,
  this.title,
  this.actionText,
  this.technicalLog,
  this.stackTrace,
}) {
  final String? title;
  final String userMessage;
  final String? actionText;
  final ErrorType type;
  final Object? technicalLog;
  final StackTrace? stackTrace;

  factory fromException(Object error, [StackTrace? stackTrace]) {
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

    final statusCode = _statusCodeFor(error);
    if (statusCode != null) {
      return _fromStatusCode(statusCode, createFailure);
    }

    if (_isRequestTimeout(error)) {
      return createFailure(
        title: 'Request timed out',
        userMessage: 'The request took too long. Try again.',
        actionText: 'Retry',
        type: ErrorType.server,
      );
    }

    if (_isOffline(error)) {
      return createFailure(
        title: 'No connection',
        userMessage: "Couldn't connect. Check your internet connection and try again.",
        actionText: 'Retry',
        type: ErrorType.network,
      );
    }

    if (_isSocketDisconnected(error)) {
      return createFailure(
        title: 'Connection interrupted',
        userMessage: "Couldn't connect. Check your internet connection and try again.",
        actionText: 'Retry',
        type: ErrorType.network,
      );
    }

    if (error is ValidationFailure) {
      return createFailure(
        userMessage: 'Check the highlighted fields.',
        actionText: 'Review',
        type: ErrorType.validation,
      );
    }

    if (error is NetworkFailure) {
      return createFailure(
        title: 'No connection',
        userMessage: "Couldn't connect. Check your internet connection and try again.",
        actionText: 'Retry',
        type: ErrorType.network,
      );
    }

    if (error is CacheFailure) {
      return createFailure(
        title: 'Saved information unavailable',
        userMessage: 'Saved information is unavailable. Try again.',
        actionText: 'Retry',
        type: ErrorType.unknown,
      );
    }

    if (error is ServerFailure || error is DataParsingException) {
      return createFailure(
        title: 'Something went wrong',
        userMessage: 'Something went wrong. Try again.',
        actionText: 'Retry',
        type: ErrorType.server,
      );
    }

    if (error is Failure) {
      return createFailure(userMessage: error.message, type: ErrorType.unknown);
    }

    return createFailure(
      userMessage: 'Something went wrong. Try again.',
      actionText: 'Retry',
      type: ErrorType.unknown,
    );
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
    return switch (statusCode) {
      401 => createFailure(
        title: 'Session expired',
        userMessage: 'Your session has expired. Sign in again.',
        actionText: 'Sign in',
        type: ErrorType.unauthorized,
      ),
      403 => createFailure(
        title: 'Access restricted',
        userMessage: "You don't have permission to do that.",
        actionText: 'Go back',
        type: ErrorType.unauthorized,
      ),
      400 || 422 => createFailure(
        userMessage: 'Check the highlighted fields.',
        actionText: 'Review',
        type: ErrorType.validation,
      ),
      429 => createFailure(
        title: 'Too many requests',
        userMessage: 'Too many requests. Wait a moment and try again.',
        type: ErrorType.server,
      ),
      503 => createFailure(
        title: 'Service unavailable',
        userMessage: 'The service is unavailable. Try again later.',
        actionText: 'Retry',
        type: ErrorType.server,
      ),
      504 => createFailure(
        title: 'Request timed out',
        userMessage: 'The request took too long. Try again.',
        actionText: 'Retry',
        type: ErrorType.server,
      ),
      >= 500 => createFailure(
        title: 'Something went wrong',
        userMessage: 'Something went wrong. Try again.',
        actionText: 'Retry',
        type: ErrorType.server,
      ),
      _ => createFailure(
        userMessage: 'Something went wrong. Try again.',
        actionText: 'Retry',
        type: ErrorType.unknown,
      ),
    };
  }

  static int? _statusCodeFor(Object error) {
    if (error is DioException) return error.response?.statusCode;
    if (error is ServerException) {
      return error.statusCode == 0 ? null : error.statusCode;
    }
    if (error is ServerFailure) return error.statusCode;
    return null;
  }

  static bool _isRequestTimeout(Object error) {
    if (error is TimeoutException) return true;
    if (error is! DioException) return false;
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => true,
      _ => false,
    };
  }

  static bool _isOffline(Object error) {
    if (error is SocketException) return true;
    if (error is ServerException && error.statusCode == 0) return true;
    if (error is ServerFailure && error.statusCode == 0) return true;
    return error is DioException &&
        (error.error is SocketException ||
            error.error is NetworkCircuitOpenException ||
            error.type == DioExceptionType.connectionError &&
                error.error == null);
  }

  static bool _isSocketDisconnected(Object error) {
    return error is DioException &&
        error.type == DioExceptionType.connectionError &&
        error.error is! SocketException;
  }

  static void _logTechnicalError(Object error, StackTrace? stackTrace) {
    developer.log(
      'Client error mapped to a safe user message.',
      name: 'shared-error-handler',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
