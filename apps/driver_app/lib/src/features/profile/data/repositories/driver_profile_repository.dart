import 'package:dio/dio.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/activity/domain/repositories/i_driver_activity_repository.dart';
import 'package:driver_app/src/features/profile/data/datasources/driver_profile_remote_data_source.dart';
import 'package:driver_app/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:driver_app/src/features/profile/domain/repositories/i_driver_profile_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverProfileRepository implements IDriverProfileRepository {
  DriverProfileRepository({
    required DriverProfileRemoteDataSource profileDataSource,
    required IDriverActivityRepository activityRepository,
    required SecureSessionService sessionService,
    required SharedPreferences preferences,
  }) : _profileDataSource = profileDataSource,
       _activityRepository = activityRepository,
       _sessionService = sessionService,
       _preferences = preferences;

  final DriverProfileRemoteDataSource _profileDataSource;
  final IDriverActivityRepository _activityRepository;
  final SecureSessionService _sessionService;
  final SharedPreferences _preferences;

  @override
  DriverAccountSnapshot getCachedAccount() {
    return DriverAccountSnapshot(
      name: _preferences.getString('driver_name') ?? '',
      email: _preferences.getString('driver_email') ?? '',
      vehicleType: _preferences.getString('vehicle_type') ?? '',
      plateNumber: _preferences.getString('plate_number') ?? '',
      ratingLabel: _preferences.getString('rating') ?? '—',
    );
  }

  @override
  Future<Either<Failure, DriverAccountSnapshot>> refreshAccount() async {
    try {
      final driverId = await _sessionService.readDriverId() ?? '';
      if (driverId.isEmpty) {
        return const Left(CacheFailure('Driver ID is not registered.'));
      }
      final profileFuture = _profileDataSource.fetchProfile(driverId);
      final statsFuture = _activityRepository.fetchStats(driverId);
      final profileValues = await profileFuture;
      final statsResult = await statsFuture;
      final statsFailure = statsResult.fold((failure) => failure, (_) => null);
      if (statsFailure != null) return Left(statsFailure);
      final cached = getCachedAccount();
      final profile = ProfileModel.fromJson(profileValues);
      final stats = statsResult.getOrElse(
        (_) => throw DataParsingException(
          message: 'Driver statistics response is incomplete.',
        ),
      );
      final ratingValue = profile.rating;
      final snapshot = DriverAccountSnapshot(
        name: profile.name.isEmpty ? cached.name : profile.name,
        email: profile.email.isEmpty ? cached.email : profile.email,
        vehicleType: profile.vehicleType.isEmpty
            ? cached.vehicleType
            : profile.vehicleType,
        plateNumber: profile.plateNumber.isEmpty
            ? cached.plateNumber
            : profile.plateNumber,
        ratingLabel: ratingValue != null && ratingValue > 0
            ? ratingValue.toStringAsFixed(1)
            : cached.ratingLabel,
        totalTrips: stats.totalTrips,
        completedTrips: stats.completedTrips,
        lifetimeEarnings: stats.totalEarningsCentavos / 100,
        averageRating: stats.averageRating > 0
            ? stats.averageRating
            : ratingValue ?? 0,
      );
      await Future.wait<void>([
        _preferences.setString('driver_name', snapshot.name),
        _preferences.setString('driver_email', snapshot.email),
        _preferences.setString('vehicle_type', snapshot.vehicleType),
        _preferences.setString('plate_number', snapshot.plateNumber),
        _preferences.setString('rating', snapshot.ratingLabel),
      ]);
      return Right(snapshot);
    } catch (error) {
      return Left(_mapFailure(error));
    }
  }
}

Failure _mapFailure(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      return const AuthFailure('Your driver session has ended. Sign in again.');
    }
    if (statusCode == null) {
      return const NetworkFailure(
        'Unable to refresh your account. Check your connection.',
      );
    }
  }
  if (error is ServerException) return ServerFailure(error.message);
  if (error is FormatException || error is DataParsingException) {
    return const ValidationFailure('Driver account data is invalid.');
  }
  return const ServerFailure('Your driver account is temporarily unavailable.');
}
