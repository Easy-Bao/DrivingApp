import 'package:foundation/foundation.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/auth/data/datasources/auth_endpoints.dart';
import 'package:passenger/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:passenger/src/features/auth/domain/failures/auth_failures.dart';
import 'package:passenger/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this._remoteDataSource,
    required this._secureSessionService,
    required this._preferences,
  });

  final AuthRemoteDataSource _remoteDataSource;
  final SessionStore _secureSessionService;
  final SharedPreferences _preferences;

  @override
  Future<Result<AuthCredentials, Failure>> authenticate({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final responseData = await _remoteDataSource.postData(
        AccountAuthEndpoints.login,
        requestBody: {
          'email': email,
          'password': password,
          'role': 'passenger',
        },
      );
      final credentials = _credentialsFromResponse(
        responseData,
        fallbackEmail: email,
      );
      await _persistSession(credentials, rememberMe: rememberMe);
      return Ok(credentials);
    } on ServerException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return const Err(InvalidCredentialsFailure());
      }
      return Err(
        FailureMapper.fromException(
          error,
          serverMessage: "Couldn't sign in. Try again.",
        ),
      );
    } catch (error) {
      return Err(
        FailureMapper.fromException(
          error,
          serverMessage: "Couldn't sign in. Try again.",
        ),
      );
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
        AccountAuthEndpoints.register,
        requestBody: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'role': 'passenger',
        },
      );
      await _secureSessionService.configurePersistence(rememberMe: true);
      if (responseData['needsVerification'] != true) {
        final credentials = _credentialsFromResponse(
          responseData,
          fallbackEmail: email,
        );
        await _persistSession(credentials);
      }
      return Ok(responseData);
    } catch (error) {
      if (error is ServerException && error.statusCode == 409) {
        return const Err(EmailAlreadyRegisteredFailure());
      }
      return Err(
        FailureMapper.fromException(
          error,
          serverMessage: "Couldn't create your account. Try again.",
          validationMessage: 'Check your registration details and try again.',
        ),
      );
    }
  }

  @override
  Future<Result<AuthCredentials, Failure>> verifyOtp({
    required String email,
    required String code,
  }) async {
    try {
      final responseData = await _remoteDataSource.postData(
        AccountAuthEndpoints.verifyOtp,
        requestBody: {'email': email, 'code': code},
      );
      final credentials = _credentialsFromResponse(
        responseData,
        fallbackEmail: email,
      );
      await _persistSession(credentials);
      return Ok(credentials);
    } catch (error) {
      return Err(
        FailureMapper.fromException(
          error,
          serverMessage: "Couldn't verify your code. Try again.",
          validationMessage: 'Invalid verification code. Try again.',
        ),
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
      throw const DataParsingException(
        message: 'Authentication response did not contain a valid session.',
      );
    }

    final passenger = Map<String, dynamic>.from(passengerData);
    final passengerId = _stringValue(passenger['id']);
    if (passengerId.isEmpty) {
      throw const DataParsingException(
        message: 'Authentication response did not contain a passenger ID.',
      );
    }

    final passengerEmail = _stringValue(passenger['email']);
    final refreshToken = _stringValue(responseData['refreshToken']);
    if (refreshToken.isEmpty) {
      throw const DataParsingException(
        message: 'Authentication response did not contain a refresh token.',
      );
    }
    final rawName = _stringValue(
      passenger['name'] ?? passenger['full_name'] ?? passenger['fullName'],
    );
    return AuthCredentials(
      passengerId: passengerId,
      passengerName: rawName,
      passengerEmail: passengerEmail.isEmpty ? fallbackEmail : passengerEmail,
      passengerPhone: _stringValue(passenger['phone']),
      token: token,
      refreshToken: refreshToken,
      needsVerification: responseData['needsVerification'] == true,
    );
  }

  Future<void> _persistSession(
    AuthCredentials credentials, {
    bool? rememberMe,
  }) async {
    if (rememberMe != null) {
      await _secureSessionService.configurePersistence(rememberMe: rememberMe);
    }
    await _secureSessionService.saveToken(credentials.token);
    await _secureSessionService.saveRefreshToken(credentials.refreshToken);
    await _secureSessionService.savePassengerId(credentials.passengerId);
    final incomingName = credentials.passengerName.trim();
    final cachedName = _preferences.getString('passenger_name') ?? '';
    if (incomingName.isNotEmpty && !incomingName.contains('@')) {
      await _preferences.setString('passenger_name', incomingName);
    } else if (cachedName.isEmpty || cachedName.contains('@')) {
      await _preferences.setString('passenger_name', incomingName);
    }
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
        AccountAuthEndpoints.requestOtp,
        requestBody: {'email': email},
      );
      final success = responseBody['success'] == true;
      if (!success) {
        return const Err(ServerFailure("Couldn't send a new code. Try again."));
      }
      return const Ok(null);
    } catch (error) {
      return Err(
        FailureMapper.fromException(
          error,
          serverMessage: 'Failed to send a new verification code.',
          validationMessage: 'Couldn\'t send a new code. Try again.',
        ),
      );
    }
  }

  @override
  Future<Result<void, Failure>> resetPassword({required String email}) async {
    try {
      final responseBody = await _remoteDataSource.postJson(
        AccountAuthEndpoints.forgotPassword,
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
      final failure = FailureMapper.fromException(
        error,
        serverMessage: "Couldn't send the reset code. Try again.",
        validationMessage: 'Enter a valid email address.',
      );
      if (failure is ValidationFailure) {
        return const Err(InvalidEmailFailure());
      }
      return Err(failure);
    }
  }

  @override
  Future<Result<void, Failure>> verifyResetOtp({
    required String email,
    required String code,
  }) async {
    try {
      final responseBody = await _remoteDataSource.postJson(
        AccountAuthEndpoints.verifyResetOtp,
        requestBody: {'email': email, 'code': code},
      );
      if (responseBody['success'] != true) {
        return const Err(InvalidVerificationCodeFailure());
      }
      return const Ok(null);
    } catch (error) {
      final failure = FailureMapper.fromException(
        error,
        serverMessage: "Couldn't verify your code. Try again.",
        validationMessage:
            'That verification code is invalid or expired. Try again.',
      );
      if (failure is ValidationFailure) {
        return const Err(InvalidVerificationCodeFailure());
      }
      return Err(failure);
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
        AccountAuthEndpoints.resetPassword,
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
      final failure = FailureMapper.fromException(
        error,
        serverMessage: 'Password reset failed. Please try again.',
        validationMessage: 'That verification code is invalid or expired. Request a new code and try again.',
      );
      if (failure is ValidationFailure) {
        return const Err(
          InvalidVerificationCodeFailure(
            'That verification code is invalid or expired. Request a new code and try again.',
          ),
        );
      }
      return Err(failure);
    }
  }
}
