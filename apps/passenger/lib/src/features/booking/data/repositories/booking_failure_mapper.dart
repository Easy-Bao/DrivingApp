import 'package:dio/dio.dart';
import 'package:foundation/foundation.dart';

Failure mapBookingFailure(
  Object error, {
  required String permissionMessage,
  required String timeoutMessage,
  required String networkMessage,
  required String serverMessage,
  Failure? validationFailure,
  String? conflictMessage,
  String? parsingMessage,
  bool handleAuth = true,
  bool handleCache = false,
}) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    if (handleAuth && statusCode == 401) {
      return const AuthFailure(
        'Your passenger session has ended. Sign in again.',
      );
    }
    if (statusCode == 403) {
      return ServerFailure.withStatusCode(permissionMessage, 403);
    }
    if ((statusCode == 400 || statusCode == 422) && validationFailure != null) {
      return validationFailure;
    }
    if (statusCode == 409 && conflictMessage != null) {
      return ServerFailure.withStatusCode(conflictMessage, 409);
    }
    if (statusCode == null) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return ServerFailure.withStatusCode(timeoutMessage, 504);
      }
      return NetworkFailure(networkMessage);
    }
    return ServerFailure.withStatusCode(serverMessage, statusCode);
  }
  if (error is ServerException) {
    if (handleAuth && error.statusCode == 401) {
      return const AuthFailure(
        'Your passenger session has ended. Sign in again.',
      );
    }
    if (error.statusCode == 403) {
      return ServerFailure.withStatusCode(permissionMessage, 403);
    }
    if ((error.statusCode == 400 || error.statusCode == 422) &&
        validationFailure != null) {
      return validationFailure;
    }
    return FailureMapper.fromException(error, serverMessage: serverMessage);
  }
  if (error is FormatException || error is DataParsingException) {
    return ValidationFailure(
      parsingMessage ?? 'The server response is invalid.',
    );
  }
  if (handleCache && error is CacheException) {
    return FailureMapper.fromException(error);
  }
  return ServerFailure(serverMessage);
}
