import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/features/auth/data/data_sources/auth_remote_data_source.dart';
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

      final token = responseData['token'] as String? ?? '';
      final passengerData = responseData['user'];
      if (token.isEmpty || passengerData is! Map) {
        throw DataParsingException(
          message: 'Authentication response did not contain a valid session.',
        );
      }

      final passenger = Map<String, dynamic>.from(passengerData);
      final passengerId = passenger['id'] as String? ?? '';
      if (passengerId.isEmpty) {
        throw DataParsingException(
          message: 'Authentication response did not contain a passenger ID.',
        );
      }

      final passengerName = passenger['name'] as String? ?? '';
      final passengerEmail = passenger['email'] as String? ?? email;
      final passengerPhone = passenger['phone'] as String? ?? '';
      final needsVerification = responseData['needsVerification'] == true;

      await _secureSessionService.saveToken(token);
      await _secureSessionService.savePassengerId(passengerId);

      await _preferences.setString('passenger_name', passengerName);
      await _preferences.setString('passenger_email', passengerEmail);
      await _preferences.setString('passenger_phone', passengerPhone);

      return Right(
        AuthCredentials(
          passengerId: passengerId,
          passengerName: passengerName,
          passengerEmail: passengerEmail,
          passengerPhone: passengerPhone,
          token: token,
          needsVerification: needsVerification,
        ),
      );
    } on ServerException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return const Left(AuthFailure('Invalid email or password.'));
      }
      if (error.statusCode == 0) {
        return Left(NetworkFailure(error.message));
      }
      return Left(ServerFailure(error.message));
    } on DataParsingException catch (error) {
      return Left(ServerFailure(error.message));
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
      return Right(responseData);
    } catch (error) {
      if (error is ServerException) {
        return Left(ValidationFailure(error.message));
      }
      final msg = error.toString().contains('already exists')
          ? 'This email is already registered.'
          : 'Registration failed. Please try again.';
      return Left(ValidationFailure(msg));
    }
  }

  @override
  Future<Either<Failure, AuthCredentials>> verifyOtp({
    required String email,
    required String code,
    required String password,
  }) async {
    try {
      final success = await _remoteDataSource.verifyOtp(
        email: email,
        code: code,
      );
      if (!success) {
        return const Left(
          ValidationFailure('Invalid or expired verification code.'),
        );
      }
      if (password.isNotEmpty) {
        return authenticatePassenger(email: email, password: password);
      }
      return Right(
        AuthCredentials(
          passengerId: '',
          passengerName: '',
          passengerEmail: email,
          passengerPhone: '',
          token: '',
          needsVerification: false,
        ),
      );
    } catch (error) {
      if (error is ServerException) {
        return Left(ValidationFailure(error.message));
      }
      return const Left(
        ServerFailure('Verification failed. Please try again.'),
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
