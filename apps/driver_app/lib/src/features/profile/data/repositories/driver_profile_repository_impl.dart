import 'package:driver_app/src/features/profile/domain/entities/profile_model.dart';
import 'package:driver_app/src/infrastructure/session/driver_session_store.dart';
import 'package:driver_app/src/features/profile/data/data_sources/driver_profile_remote_data_source.dart';
import 'package:driver_app/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:driver_app/src/features/profile/domain/repositories/driver_profile_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:foundation/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class DriverProfileRepositoryImpl({
  required DriverProfileRemoteDataSource profileDataSource,
  required DriverSessionStore sessionService,
  required SharedPreferences preferences,
}) implements DriverProfileRepository {
  this
    : _profileDataSource = profileDataSource,
      _sessionService = sessionService,
      _preferences = preferences;

  final DriverProfileRemoteDataSource _profileDataSource;
  final DriverSessionStore _sessionService;
  final SharedPreferences _preferences;

  @override
  DriverAccountSnapshot getCachedAccount() {
    return DriverAccountSnapshot(
      name: _preferences.getString('driver_name') ?? '',
      phone: _preferences.getString('driver_phone') ?? '',
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
      final profileValues = await _profileDataSource.fetchProfile(driverId);
      final cached = getCachedAccount();
      final profile = ProfileModel.fromJson(profileValues);
      final ratingValue = profile.rating;
      final snapshot = DriverAccountSnapshot(
        name: profile.name.isEmpty ? cached.name : profile.name,
        phone: profile.phone.isEmpty ? cached.phone : profile.phone,
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
        totalTrips: cached.totalTrips,
        completedTrips: cached.completedTrips,
        lifetimeEarnings: cached.lifetimeEarnings,
        averageRating: cached.averageRating,
      );
      await _cacheAccount(snapshot);
      return Right(snapshot);
    } catch (error) {
      return Left(_mapFailure(error));
    }
  }

  @override
  Future<Either<Failure, DriverAccountSnapshot>> updateAccount({
    required DriverAccountSnapshot currentAccount,
    required String name,
    required String phone,
    required String email,
    required String vehicleType,
    required String plateNumber,
  }) async {
    final normalizedName = name.trim();
    final normalizedPhone = _normalizePhone(phone);
    final normalizedEmail = email.trim();
    final normalizedVehicleType = vehicleType.trim();
    final normalizedPlateNumber = plateNumber.trim();

    if (normalizedName.isEmpty ||
        normalizedPhone.isEmpty ||
        normalizedPhone.replaceAll(RegExp(r'[^0-9]'), '').length < 12 ||
        normalizedEmail.isEmpty ||
        !normalizedEmail.contains('@') ||
        normalizedVehicleType.isEmpty ||
        normalizedPlateNumber.isEmpty) {
      return const Left(
        ValidationFailure('Please verify your driver details.'),
      );
    }

    try {
      final response = await _profileDataSource.updateProfile(
        data: {
          'name': normalizedName,
          'phone': normalizedPhone,
          'email': normalizedEmail,
          'vehicle_type': normalizedVehicleType,
          'plate_number': normalizedPlateNumber,
        },
      );
      final profile = ProfileModel.fromJson(response);
      final updated = DriverAccountSnapshot(
        name: profile.name.isEmpty ? normalizedName : profile.name,
        phone: profile.phone.isEmpty ? normalizedPhone : profile.phone,
        email: profile.email.isEmpty ? normalizedEmail : profile.email,
        vehicleType: profile.vehicleType.isEmpty
            ? normalizedVehicleType
            : profile.vehicleType,
        plateNumber: profile.plateNumber.isEmpty
            ? normalizedPlateNumber
            : profile.plateNumber,
        ratingLabel: currentAccount.ratingLabel,
        totalTrips: currentAccount.totalTrips,
        completedTrips: currentAccount.completedTrips,
        lifetimeEarnings: currentAccount.lifetimeEarnings,
        averageRating: currentAccount.averageRating,
      );
      await _cacheAccount(updated);
      return Right(updated);
    } catch (error) {
      return Left(_mapFailure(error));
    }
  }

  Future<void> _cacheAccount(DriverAccountSnapshot account) async {
    await Future.wait<void>([
      _preferences.setString('driver_name', account.name),
      _preferences.setString('driver_phone', account.phone),
      _preferences.setString('driver_email', account.email),
      _preferences.setString('vehicle_type', account.vehicleType),
      _preferences.setString('plate_number', account.plateNumber),
      _preferences.setString('rating', account.ratingLabel),
    ]);
  }

  String _normalizePhone(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('63')) return '+$digits';
    if (digits.startsWith('0')) return '+63${digits.substring(1)}';
    return digits.isEmpty ? '' : '+63$digits';
  }
}

Failure _mapFailure(Object error) {
  return FailureMapper.fromException(
    error,
    serverMessage: 'Your driver account is temporarily unavailable.',
    validationMessage: 'Please verify your driver details.',
    networkMessage: 'Unable to refresh your account. Check your connection.',
    timeoutMessage: 'Driver account request timed out.',
    cacheMessage: 'Saved driver information is unavailable. Please try again.',
  );
}
