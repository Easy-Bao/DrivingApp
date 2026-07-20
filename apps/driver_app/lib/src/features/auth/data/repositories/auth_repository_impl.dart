import 'package:core_models/core_models.dart';
import 'package:driver_app/src/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:driver_app/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:driver_app/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';
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
  Future<Either<Failure, AuthCredentials>> authenticateDriver({
    required String email,
    required String password,
  }) async {
    try {
      final responseData = await _remoteDataSource.authenticateDriver(
        email: email,
        password: password,
      );

      final driver = responseData['driver'] as Map<String, dynamic>;
      final driverId = driver['id'] as String? ?? '';
      final driverName = driver['name'] as String? ?? '';
      final driverEmail = driver['email'] as String? ?? '';
      final vehicleType = driver['vehicleType'] as String? ?? 'Bao Bao';
      final plateNumber = driver['plateNumber'] as String? ?? 'ABC 1234';
      final rating = (driver['rating'] as num?)?.toDouble() ?? 5.0;

      await _secureSessionService.writeDriverId(driverId);

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
      return const Left(
        AuthFailure('Invalid email or password'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String email,
  }) async {
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
