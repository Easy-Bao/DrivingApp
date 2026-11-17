import 'package:dio/dio.dart';
import 'package:foundation/src/errors/exceptions.dart';
import 'package:foundation/src/errors/failure.dart';
import 'package:foundation/src/errors/network_diagnostic.dart';

const _defaultServerMessage =
    'The server could not complete your request. Try again.';
const _defaultValidationMessage = 'Check the highlighted fields.';
const _defaultNetworkMessage =
    "Couldn't connect. Check your internet connection and try again.";
const _defaultTimeoutMessage = 'The request took too long. Try again.';
const _defaultCacheMessage = 'Saved information is unavailable. Try again.';

/// Data sources may contain backend-provided details, but those details must
/// stay in technical logs. Repositories use this mapper before a failure can
/// cross into a BLoC or view.
class FailureMapper {
  const FailureMapper._();

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
      timeoutMessage: timeoutMessage,
    );

    if (error is NetworkFailure) return error;
    if (error is CacheFailure || error is CacheException) {
      return CacheFailure(cacheMessage);
    }
    if (error is ValidationFailure) {
      return ValidationFailure(validationMessage);
    }
    if (error is UnexpectedFailure) return error;
    if (error is ServerFailure) return mapStatus(error.statusCode);
    if (error is ServerException && error.statusCode != 0) {
      return mapStatus(error.statusCode);
    }
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode != null) return mapStatus(statusCode);
    }

    final diagnostic = NetworkErrorDiagnostic.fromError(error);
    final mapped = mapDiagnosticCategoryToFailure(
      diagnostic.category,
      offlineMessage: networkMessage,
      timeoutMessage: timeoutMessage,
    );
    if (mapped != null) return mapped;

    if (error is Failure) return error;
    if (error is DioException) return UnexpectedFailure(serverMessage);
    return ServerFailure(serverMessage);
  }

  static Failure _fromStatusCode(
    int? statusCode, {
    required String serverMessage,
    required String validationMessage,
    required String timeoutMessage,
  }) {
    if (statusCode == null || statusCode == 0) {
      return UnexpectedFailure(serverMessage);
    }
    if (statusCode == 400 || statusCode == 422) {
      return ValidationFailure(validationMessage);
    }
    if (statusCode == 408 || statusCode == 504) {
      return ServerFailure.withStatusCode(timeoutMessage, statusCode);
    }
    if (statusCode >= 500 && statusCode != 502 && statusCode != 503) {
      return ServerFailure.withStatusCode(serverMessage, statusCode);
    }
    return ServerFailure.withStatusCode(
      describeHttpStatusFailure(statusCode).userMessage,
      statusCode,
    );
  }
}
