import 'package:foundation/src/core/result.dart';
import 'package:foundation/src/errors/failure.dart';
import 'package:foundation/src/errors/failure_mapper.dart';

/// Retains returned failures and maps exceptions thrown by an implementation.
Future<Result<T, Failure>> captureResult<T>(
  Future<Result<T, Failure>> Function() operation, {
  required String message,
}) async {
  try {
    return await operation();
  } catch (error) {
    return Err<T, Failure>(
      FailureMapper.fromException(error, serverMessage: message),
    );
  }
}
