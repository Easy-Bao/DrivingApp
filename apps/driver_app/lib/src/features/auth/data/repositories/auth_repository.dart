import 'package:core_models/core_models.dart';
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
      final token = authenticationData['token'] as String? ?? '';
      final driver =
          (authenticationData['driver'] as Map<String, dynamic>?) ??
          (authenticationData['user'] as Map<String, dynamic>?) ??
          authenticationData;
      final driverId = driver['id'] as String? ?? '';
      final driverName = driver['name'] as String? ?? '';
      final driverEmail = driver['email'] as String? ?? '';
      final vehicleType =
          driver['vehicleType'] as String? ?? 'Vehicle type unavailable';
      final plateNumber =
          driver['plateNumber'] as String? ?? 'Vehicle plate unavailable';
      final rating = (driver['rating'] as num?)?.toDouble() ?? 0.0;

      if (token.isEmpty || driverId.isEmpty) {
        throw const FormatException('Authentication response is incomplete');
      }

      await _secureSessionService.saveToken(token);
      await _secureSessionService.saveDriverId(driverId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('driver_id', driverId);
      await prefs.setString('driver_name', driverName);
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
    } catch (error) {
      return const Left(AuthFailure('Invalid email or password'));
    }
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
