import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:passenger_app/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:passenger_app/src/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository implements IAuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureSessionService _secureSessionService;
  final SharedPreferences _preferences;

  AuthRepository({
    required AuthRemoteDataSource remoteDataSource,
    required SecureSessionService secureSessionService,
    required SharedPreferences preferences,
  }) : _remoteDataSource = remoteDataSource,
       _secureSessionService = secureSessionService,
       _preferences = preferences;

  @override
  Future<Either<Failure, AuthCredentials>> authenticatePassenger({
    required String email,
    required String password,
  }) async {
    try {
      final responseData = await _remoteDataSource.loginPassenger(
        email: email,
        password: password,
      );
      final credentials = _credentialsFromResponse(
        responseData,
        fallbackEmail: email,
      );
      await _persistSession(credentials);
      return Right(credentials);
    } on ServerException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return const Left(InvalidCredentialsFailure());
      }
      if (error.statusCode == 0) {
        return const Left(NetworkFailure());
      }
      return Left(
        FailureMapper.fromException(
          error,
          serverMessage: 'Unable to sign in right now. Please try again.',
        ),
      );
    } on DataParsingException catch (error) {
      return Left(
        FailureMapper.fromException(
          error,
          serverMessage: 'Unable to sign in right now. Please try again.',
        ),
      );
    } catch (_) {
      return const Left(
        ServerFailure('Unable to sign in right now. Please try again.'),
      );
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> registerPassenger({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final responseData = await _remoteDataSource.registerPassenger(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      if (responseData['needsVerification'] != true) {
        final credentials = _credentialsFromResponse(
          responseData,
          fallbackEmail: email,
        );
        await _persistSession(credentials);
      }
      return Right(responseData);
    } catch (error) {
      if (error is ServerException) {
        if (error.statusCode == 409) {
          return const Left(EmailAlreadyRegisteredFailure());
        }
        if (error.statusCode == 0) {
          return const Left(NetworkFailure());
        }
        return Left(
          FailureMapper.fromException(
            error,
            validationMessage: 'Please verify your registration details.',
          ),
        );
      }
      return const Left(
        ServerFailure('Registration failed. Please try again.'),
      );
    }
  }

  @override
  Future<Either<Failure, AuthCredentials>> verifyOtp({
    required String email,
    required String code,
  }) async {
    try {
      final responseData = await _remoteDataSource.verifyOtp(
        email: email,
        code: code,
      );
      final credentials = _credentialsFromResponse(
        responseData,
        fallbackEmail: email,
      );
      await _persistSession(credentials);
      return Right(credentials);
    } catch (error) {
      if (error is ServerException) {
        return Left(
          FailureMapper.fromException(
            error,
            validationMessage: 'Please verify the code and try again.',
          ),
        );
      }
      return const Left(
        ServerFailure('Verification failed. Please try again.'),
      );
    }
  }

  AuthCredentials _credentialsFromResponse(
    Map<String, dynamic> responseData, {
    required String fallbackEmail,
  }) {
    final token = _stringValue(responseData['token']);
    final passengerData = responseData['user'];
    if (token.isEmpty || passengerData is! Map) {
      throw DataParsingException(
        message: 'Authentication response did not contain a valid session.',
      );
    }

    final passenger = Map<String, dynamic>.from(passengerData);
    final passengerId = _stringValue(passenger['id']);
    if (passengerId.isEmpty) {
      throw DataParsingException(
        message: 'Authentication response did not contain a passenger ID.',
      );
    }

    final passengerEmail = _stringValue(passenger['email']);
    return AuthCredentials(
      passengerId: passengerId,
      passengerName: _stringValue(passenger['name']),
      passengerEmail: passengerEmail.isEmpty ? fallbackEmail : passengerEmail,
      passengerPhone: _stringValue(passenger['phone']),
      token: token,
      refreshToken: _stringValue(responseData['refreshToken']),
      needsVerification: responseData['needsVerification'] == true,
    );
  }

  Future<void> _persistSession(AuthCredentials credentials) async {
    await _secureSessionService.saveToken(credentials.token);
    await _secureSessionService.saveRefreshToken(credentials.refreshToken);
    await _secureSessionService.savePassengerId(credentials.passengerId);
    await _preferences.setString('passenger_name', credentials.passengerName);
    await _preferences.setString('passenger_email', credentials.passengerEmail);
    await _preferences.setString('passenger_phone', credentials.passengerPhone);
  }

  String _stringValue(Object? value) => value?.toString() ?? '';

  @override
  Future<Either<Failure, void>> requestVerificationCode({
    required String email,
  }) async {
    try {
      final success = await _remoteDataSource.requestVerificationCode(
        email: email,
      );
      if (!success) {
        return const Left(
          ServerFailure('Failed to send a new verification code.'),
        );
      }
      return const Right(null);
    } on ServerException catch (error) {
      return Left(
        FailureMapper.fromException(
          error,
          validationMessage:
              'Unable to send a new verification code. Please try again.',
        ),
      );
    } catch (_) {
      return const Left(
        ServerFailure('Failed to send a new verification code.'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({required String email}) async {
    try {
      final success = await _remoteDataSource.resetPassword(email: email);
      if (!success) {
        return const Left(
          ServerFailure('Failed to send reset link. Please check email.'),
        );
      }
      return const Right(null);
    } catch (error) {
      return const Left(
        ServerFailure('Failed to send reset link. Please try again.'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> confirmResetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final success = await _remoteDataSource.confirmResetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      if (!success) {
        return const Left(
          ServerFailure('Password reset failed. Please try again.'),
        );
      }
      return const Right(null);
    } catch (error) {
      return const Left(
        ServerFailure('Password reset failed. Please try again.'),
      );
    }
  }
}
