import 'package:dio/dio.dart';
import 'package:passenger_app/src/core/errors/failures.dart';

class ErrorHandler {
  static Failure handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkFailure('Connection timeout. Please check your network.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final msg = error.response?.data?['message'] as String? ?? 'Server returned error $statusCode';
        return ServerFailure(msg);
      default:
        return ServerFailure(error.message ?? 'An unexpected network error occurred.');
    }
  }
}
