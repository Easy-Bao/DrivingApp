import 'package:shared_core/shared_core.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:driver_app/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:driver_app/src/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:fpdart/fpdart.dart';

import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository implements IAuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureSessionService _secureSessionService;

  AuthRepository({
    required AuthRemoteDataSource remoteDataSource,
    required SecureSessionService secureSessionService,
  }) : _remoteDataSource = remoteDataSource,
       _secureSessionService = secureSessionService;

  @override
  Future<Either<Failure, AuthCredentials>> authenticateDriver({
    required String email,
    required String password,
  }) async {
    try {
      final responseData = await _remoteDataSource.authenticateDriver(
        email: email,
        password: password,
      );

      final authenticationData =
          (responseData['data'] as Map<String, dynamic>?) ?? responseData;
      final token = _stringValue(authenticationData['token']);
      final driverData =
          authenticationData['driver'] ?? authenticationData['user'];
      if (driverData is! Map) {
        throw DataParsingException(
          message: 'Authentication response did not contain a driver.',
        );
      }
      final driver = Map<String, dynamic>.from(driverData);
      // Availability endpoints are authorized with the user ID from the JWT.
      // Older profile-shaped login responses also contained a separate
      // profile ID, so prefer the account ID when either shape is returned.
      final driverId = _firstNonEmptyString([
        driver['userId'],
        driver['user_id'],
        driver['id'],
      ]);
      final driverName = _stringValue(driver['name']);
      final driverPhone = _firstNonEmptyString([
        driver['phone'],
        driver['phoneNumber'],
        driver['phone_number'],
      ]);
      final driverEmail = _stringValue(driver['email']);
      final vehicleType = _stringValue(driver['vehicleType']).isEmpty
          ? 'Vehicle type unavailable'
          : _stringValue(driver['vehicleType']);
      final plateNumber = _stringValue(driver['plateNumber']).isEmpty
          ? 'Vehicle plate unavailable'
          : _stringValue(driver['plateNumber']);
      final rating = (driver['rating'] as num?)?.toDouble() ?? 0.0;

      if (token.isEmpty || driverId.isEmpty) {
        throw const FormatException('Authentication response is incomplete');
      }

      await _secureSessionService.saveToken(token);
      await _secureSessionService.saveRefreshToken(
        _stringValue(authenticationData['refreshToken']),
      );
      await _secureSessionService.saveDriverId(driverId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('driver_id', driverId);
      await prefs.setString('driver_name', driverName);
      await prefs.setString('driver_phone', driverPhone);
      await prefs.setString('driver_email', driverEmail);
      await prefs.setString('vehicle_type', vehicleType);
      await prefs.setString('plate_number', plateNumber);
      await prefs.setString('rating', rating.toString());

      final credentials = AuthCredentials(
        driverId: driverId,
        driverName: driverName,
        driverEmail: driverEmail,
        vehicleType: vehicleType,
        plateNumber: plateNumber,
        rating: rating,
      );

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

  String _stringValue(Object? value) => value?.toString() ?? '';

  String _firstNonEmptyString(Iterable<Object?> values) {
    for (final value in values) {
      final stringValue = _stringValue(value);
      if (stringValue.isNotEmpty) return stringValue;
    }
    return '';
  }

  @override
  Future<Either<Failure, void>> resetPassword({required String email}) async {
    try {
      await _remoteDataSource.resetPassword(email: email);
      return const Right(null);
    } catch (error) {
      return const Left(
        ServerFailure('Failed to send reset link. Please try again.'),
      );
    }
  }
}
