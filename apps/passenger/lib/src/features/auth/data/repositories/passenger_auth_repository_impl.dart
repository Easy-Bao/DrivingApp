import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/auth/data/data_sources/passenger_auth_remote_data_source.dart';
import 'package:passenger/src/features/auth/data/passenger_auth_endpoints.dart';
import 'package:passenger/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:passenger/src/features/auth/domain/failures/auth_failures.dart';
import 'package:passenger/src/features/auth/domain/repositories/passenger_auth_repository.dart';
import 'package:passenger/src/infrastructure/session/passenger_session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class PassengerAuthRepositoryImpl({
  required this._remoteDataSource,
  required this._secureSessionService,
  required this._preferences,
}) implements PassengerAuthRepository {
  final PassengerAuthRemoteDataSource _remoteDataSource;
  final PassengerSessionStore _secureSessionService;
  final SharedPreferences _preferences;

  @override
  Future<Result<PassengerAuthCredentials, Failure>> authenticate({
    required String email,
    required String password,
  }) async {
    try {
      final responseData = await _remoteDataSource.postData(
        PassengerAuthEndpoints.login,
        requestBody: {'email': email, 'password': password},
      );
      final credentials = _credentialsFromResponse(
        responseData,
        fallbackEmail: email,
      );
      await _persistSession(credentials);
      return Ok(credentials);
    } on ServerException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return const Err(InvalidCredentialsFailure());
      }
      if (error.statusCode == 0) {
        return const Err(NetworkFailure());
      }
      return Err(
        FailureMapper.fromException(
          error,
          serverMessage: "Couldn't sign in. Try again.",
        ),
      );
    } on DataParsingException catch (error) {
      return Err(
        FailureMapper.fromException(
          error,
          serverMessage: "Couldn't sign in. Try again.",
        ),
      );
    } catch (_) {
      return const Err(ServerFailure("Couldn't sign in. Try again."));
    }
  }

  @override
  Future<Result<Map<String, dynamic>, Failure>> registerPassenger({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final responseData = await _remoteDataSource.postData(
        PassengerAuthEndpoints.register,
        requestBody: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        },
      );
      if (responseData['needsVerification'] != true) {
        final credentials = _credentialsFromResponse(
          responseData,
          fallbackEmail: email,
        );
        await _persistSession(credentials);
      }
      return Ok(responseData);
    } catch (error) {
      if (error is ServerException) {
        if (error.statusCode == 409) {
          return const Err(EmailAlreadyRegisteredFailure());
        }
        if (error.statusCode == 0) {
          return const Err(NetworkFailure());
        }
        return Err(
          FailureMapper.fromException(
            error,
            validationMessage: 'Check your registration details and try again.',
          ),
        );
      }
      return const Err(
        ServerFailure("Couldn't create your account. Try again."),
      );
    }
  }

  @override
  Future<Result<PassengerAuthCredentials, Failure>> verifyOtp({
    required String email,
    required String code,
  }) async {
    try {
      final responseData = await _remoteDataSource.postData(
        PassengerAuthEndpoints.verifyOtp,
        requestBody: {'email': email, 'code': code},
      );
      final credentials = _credentialsFromResponse(
        responseData,
        fallbackEmail: email,
      );
      await _persistSession(credentials);
      return Ok(credentials);
    } catch (error) {
      if (error is ServerException) {
        return Err(
          FailureMapper.fromException(
            error,
            validationMessage: 'Invalid verification code. Try again.',
          ),
        );
      }
      return const Err(ServerFailure("Couldn't verify your code. Try again."));
    }
  }

  PassengerAuthCredentials _credentialsFromResponse(
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
    final refreshToken = _stringValue(responseData['refreshToken']);
    if (refreshToken.isEmpty) {
      throw DataParsingException(
        message: 'Authentication response did not contain a refresh token.',
      );
    }
    return PassengerAuthCredentials(
      passengerId: passengerId,
      passengerName: _stringValue(passenger['name']),
      passengerEmail: passengerEmail.isEmpty ? fallbackEmail : passengerEmail,
      passengerPhone: _stringValue(passenger['phone']),
      token: token,
      refreshToken: refreshToken,
      needsVerification: responseData['needsVerification'] == true,
    );
  }

  Future<void> _persistSession(PassengerAuthCredentials credentials) async {
    await _secureSessionService.saveToken(credentials.token);
    await _secureSessionService.saveRefreshToken(credentials.refreshToken);
    await _secureSessionService.savePassengerId(credentials.passengerId);
    await _preferences.setString('passenger_name', credentials.passengerName);
    await _preferences.setString('passenger_email', credentials.passengerEmail);
    await _preferences.setString('passenger_phone', credentials.passengerPhone);
  }

  String _stringValue(Object? value) => value?.toString() ?? '';

  @override
  Future<Result<void, Failure>> requestVerificationCode({
    required String email,
  }) async {
    try {
      final responseBody = await _remoteDataSource.postJson(
        PassengerAuthEndpoints.requestOtp,
        requestBody: {'email': email},
      );
      final success = responseBody['success'] == true;
      if (!success) {
        return const Err(ServerFailure("Couldn't send a new code. Try again."));
      }
      return const Ok(null);
    } on ServerException catch (error) {
      return Err(
        FailureMapper.fromException(
          error,
          validationMessage: 'Couldn\'t send a new code. Try again.',
        ),
      );
    } catch (_) {
      return const Err(
        ServerFailure('Failed to send a new verification code.'),
      );
    }
  }

  @override
  Future<Result<void, Failure>> resetPassword({required String email}) async {
    try {
      final responseBody = await _remoteDataSource.postJson(
        PassengerAuthEndpoints.forgotPassword,
        requestBody: {'email': email},
      );
      final success = responseBody['success'] == true;
      if (!success) {
        return const Err(
          ServerFailure(
            "Couldn't send the reset link. Check your email and try again.",
          ),
        );
      }
      return const Ok(null);
    } catch (error) {
      return const Err(
        ServerFailure("Couldn't send the reset link. Try again."),
      );
    }
  }

  @override
  Future<Result<void, Failure>> confirmResetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final responseBody = await _remoteDataSource.postJson(
        PassengerAuthEndpoints.resetPassword,
        requestBody: {'email': email, 'code': code, 'newPassword': newPassword},
      );
      final success = responseBody['success'] == true;
      if (!success) {
        return const Err(
          ServerFailure("Couldn't reset your password. Try again."),
        );
      }
      return const Ok(null);
    } catch (error) {
      return const Err(
        ServerFailure('Password reset failed. Please try again.'),
      );
    }
  }
}
