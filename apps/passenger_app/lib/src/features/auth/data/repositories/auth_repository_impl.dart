import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:passenger_app/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:passenger_app/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:session_service/session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureSessionService _secureSessionService;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SecureSessionService secureSessionService,
  })  : _remoteDataSource = remoteDataSource,
        _secureSessionService = secureSessionService;

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
      final passenger = responseData['passenger'] as Map<String, dynamic>? ?? {};
      final passengerId = passenger['id'] as String? ?? '';
      final passengerName = passenger['name'] as String? ?? '';
      final passengerEmail = passenger['email'] as String? ?? '';
      final passengerPhone = passenger['phone'] as String? ?? '';
      final needsVerification = responseData['needs_verification'] == true;

      if (token.isNotEmpty) {
        await _secureSessionService.writeAuthToken(token);
      }
      if (passengerId.isNotEmpty) {
        await _secureSessionService.writePassengerId(passengerId);
      }

      final prefs = await SharedPreferences.getInstance();
      if (token.isNotEmpty) await prefs.setString('jwt_token', token);
      if (passengerId.isNotEmpty) await prefs.setString('passenger_id', passengerId);
      await prefs.setString('passenger_name', passengerName);
      await prefs.setString('passenger_email', passengerEmail);
      await prefs.setString('passenger_phone', passengerPhone);

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
    } catch (error) {
      final errorMsg = error.toString();
      if (errorMsg.contains('No passenger registered') || errorMsg.contains('not found')) {
        return const Left(AuthFailure('No account found with this email address.'));
      }
      return const Left(AuthFailure('Invalid email or password'));
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
        return const Left(ValidationFailure('Invalid or expired verification code.'));
      }
      return authenticatePassenger(email: email, password: password);
    } catch (error) {
      return const Left(ServerFailure('Verification failed. Please try again.'));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String email,
  }) async {
    try {
      final success = await _remoteDataSource.resetPassword(email: email);
      if (!success) {
        return const Left(ServerFailure('Failed to send reset link. Please check email.'));
      }
      return const Right(null);
    } catch (error) {
      return const Left(ServerFailure('Failed to send reset link. Please try again.'));
    }
  }
}
