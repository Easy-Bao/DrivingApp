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
class AppFailure {
  final String? title;
  final String userMessage;
  final String? actionText;
  final ErrorType type;
  final Object? technicalLog;
  final StackTrace? stackTrace;

  const AppFailure({
    required this.userMessage,
    required this.type,
    this.title,
    this.actionText,
    this.technicalLog,
    this.stackTrace,
  });

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

    final statusCode = _statusCodeFor(error);
    if (statusCode != null) {
      return _fromStatusCode(statusCode, createFailure);
    }

    if (_isLocationFailure(error)) {
      return createFailure(
        title: 'Location Signal Weak',
        userMessage:
            'Unable to get an accurate location. Please move to an open area or enable high-accuracy GPS.',
        actionText: 'Enable GPS',
        type: ErrorType.location,
      );
    }

    if (_isRequestTimeout(error)) {
      return createFailure(
        title: 'Request Timed Out',
        userMessage:
            'The server took too long to respond. Please check your connection and retry.',
        actionText: 'Retry',
        type: ErrorType.server,
      );
    }

    if (_isOffline(error)) {
      return createFailure(
        title: 'No Connection',
        userMessage:
            'You are currently offline. Please check your Wi-Fi or mobile data.',
        actionText: 'Reconnect',
        type: ErrorType.network,
      );
    }

    if (_isSocketDisconnected(error)) {
      return createFailure(
        title: 'Connection Interrupted',
        userMessage:
            'Connection lost while communicating with the server. Reconnecting automatically...',
        type: ErrorType.network,
      );
    }

    if (error is NoDriversAvailableFailure) {
      return createFailure(
        title: 'No Drivers Found',
        userMessage:
            'All nearby drivers are currently busy. Please adjust your pickup point or try again shortly.',
        actionText: 'Search Again',
        type: ErrorType.unknown,
      );
    }

    if (error is RouteCalculationFailure) {
      return createFailure(
        title: 'Route Calculation Error',
        userMessage:
            'Unable to calculate route and fare right now. Please re-select your destination.',
        actionText: 'Re-select Destination',
        type: ErrorType.unknown,
      );
    }

    if (error is PaymentDeclinedFailure) {
      return createFailure(
        title: 'Payment Unsuccessful',
        userMessage:
            'We could not process your payment. Your account was not charged. Please try another payment method.',
        actionText: 'Change Payment Method',
        type: ErrorType.unknown,
      );
    }

    if (error is EmailAlreadyRegisteredFailure) {
      return createFailure(
        title: 'Email Already Registered',
        userMessage: 'This email is already registered.',
        actionText: 'Sign In',
        type: ErrorType.validation,
      );
    }

    if (error is ChatRoomLockedFailure) {
      return createFailure(
        title: 'Chat Unavailable',
        userMessage: 'This chat has already been resolved.',
        actionText: 'Go Back',
        type: ErrorType.unknown,
      );
    }

    if (error is InvalidCredentialsFailure) {
      return createFailure(
        title: 'Sign In Unsuccessful',
        userMessage: 'The email or password is incorrect.',
        actionText: 'Try Again',
        type: ErrorType.unauthorized,
      );
    }

    if (error is AuthFailure) {
      return createFailure(
        title: 'Session Expired',
        userMessage:
            'Your session has expired. Please sign in again to continue.',
        actionText: 'Sign In',
        type: ErrorType.unauthorized,
      );
    }

    if (error is ValidationFailure) {
      return createFailure(
        userMessage:
            'Please verify your input and correct the highlighted fields.',
        actionText: 'Highlight field',
        type: ErrorType.validation,
      );
    }

    if (error is NetworkFailure) {
      return createFailure(
        title: 'No Connection',
        userMessage:
            'You are currently offline. Please check your Wi-Fi or mobile data.',
        actionText: 'Reconnect',
        type: ErrorType.network,
      );
    }

    if (error is CacheFailure) {
      return createFailure(
        title: 'Saved Information Unavailable',
        userMessage:
            'Saved information is unavailable right now. Please try again.',
        actionText: 'Retry',
        type: ErrorType.unknown,
      );
    }

    if (error is ServerFailure || error is DataParsingException) {
      return createFailure(
        title: 'Something went wrong on our end',
        userMessage:
            'We encountered an unexpected issue while processing your request. Please try again in a few moments.',
        actionText: 'Try Again',
        type: ErrorType.server,
      );
    }

    return createFailure(
      userMessage: 'Unable to complete your request. Please try again.',
      actionText: 'Close',
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
        title: 'Session Expired',
        userMessage:
            'Your session has expired. Please sign in again to continue.',
        actionText: 'Sign In',
        type: ErrorType.unauthorized,
      ),
      403 => createFailure(
        title: 'Access Restricted',
        userMessage:
            'You do not have permission to view or edit this resource.',
        actionText: 'Go Back',
        type: ErrorType.unauthorized,
      ),
      400 || 422 => createFailure(
        userMessage:
            'Please verify your input and correct the highlighted fields.',
        actionText: 'Highlight field',
        type: ErrorType.validation,
      ),
      429 => createFailure(
        title: 'Too Many Requests',
        userMessage:
            'You are making requests too quickly. Please wait a moment before trying again.',
        type: ErrorType.server,
      ),
      503 => createFailure(
        title: 'Under Maintenance',
        userMessage:
            'We are currently improving our services. We will be back online shortly.',
        actionText: 'Refresh',
        type: ErrorType.server,
      ),
      504 => createFailure(
        title: 'Request Timed Out',
        userMessage:
            'The server took too long to respond. Please check your connection and retry.',
        actionText: 'Retry',
        type: ErrorType.server,
      ),
      >= 500 => createFailure(
        title: 'Something went wrong on our end',
        userMessage:
            'We encountered an unexpected issue while processing your request. Please try again in a few moments.',
        actionText: 'Try Again',
        type: ErrorType.server,
      ),
      _ => createFailure(
        userMessage: 'Unable to complete your request. Please try again.',
        actionText: 'Close',
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

  static bool _isLocationFailure(Object error) => error is LocationFailure;

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
