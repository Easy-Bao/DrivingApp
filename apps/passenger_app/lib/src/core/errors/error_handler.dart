import 'package:dio/dio.dart';
import 'package:passenger_app/src/core/errors/failures.dart';

mixin ErrorHandler {
  static Failure handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkFailure(
          'Connection timeout. Please check your network.',
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        String? msg;
        if (responseData is Map<String, dynamic>) {
          msg = responseData['message'] as String?;
        }
        return ServerFailure(msg ?? 'Server returned error $statusCode');
      default:
        return ServerFailure(
          error.message ?? 'An unexpected network error occurred.',
        );
    }
  }
}
