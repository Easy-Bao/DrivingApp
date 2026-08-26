import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/features/profile/data/datasources/passenger_profile_remote_data_source.dart';
import 'package:passenger_app/src/features/profile/domain/repositories/i_passenger_profile_repository.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PassengerProfileRepository implements IPassengerProfileRepository {
  PassengerProfileRepository({
    required PassengerProfileRemoteDataSource remoteDataSource,
    required SecureSessionService sessionService,
    required SharedPreferences preferences,
  }) : _remoteDataSource = remoteDataSource,
       _sessionService = sessionService,
       _preferences = preferences;

  final PassengerProfileRemoteDataSource _remoteDataSource;
  final SecureSessionService _sessionService;
  final SharedPreferences _preferences;

  @override
  ProfileModel getCachedProfile() {
    return ProfileModel(
      name: _preferences.getString('passenger_name') ?? '',
      phone: _preferences.getString('passenger_phone') ?? '',
      email: _preferences.getString('passenger_email') ?? '',
      address: _preferences.getString('passenger_address') ?? '',
      gender: _preferences.getString('passenger_gender') ?? '',
      avatarPath: _preferences.getString('passenger_avatar_path') ?? '',
    );
  }

  @override
  Future<Either<Failure, ProfileModel>> refreshProfile() async {
    try {
      final passengerId = await _passengerId();
      final cached = getCachedProfile();
      final remote = ProfileModel.fromJson(
        await _remoteDataSource.fetchProfile(passengerId),
      );
      final profile = ProfileModel(
        id: remote.id,
        userId: remote.userId,
        role: remote.role,
        name: remote.name.isEmpty ? cached.name : remote.name,
        phone: remote.phone.isEmpty ? cached.phone : remote.phone,
        email: remote.email.isEmpty ? cached.email : remote.email,
        address: remote.address.isEmpty ? cached.address : remote.address,
        gender: remote.gender.isEmpty ? cached.gender : remote.gender,
        avatarPath: cached.avatarPath,
        preferredRideType: remote.preferredRideType,
      );
      await _cache(profile);
      return Right(profile);
    } catch (error) {
      return Left(_mapFailure(error));
    }
  }

  @override
  Future<Either<Failure, ProfileModel>> updateProfile({
    required String name,
    required String phone,
    required String email,
    required String address,
    required String gender,
    required String avatarPath,
  }) async {
    final normalizedName = name.trim();
    final normalizedPhone = phone.trim();
    final normalizedEmail = email.trim();
    if (normalizedName.isEmpty ||
        normalizedPhone.isEmpty ||
        normalizedEmail.isEmpty ||
        !normalizedEmail.contains('@')) {
      return const Left(ValidationFailure('Profile values are invalid.'));
    }
    try {
      final passengerId = await _passengerId();
      final response = await _remoteDataSource.updateProfile(
        passengerId: passengerId,
        data: {
          'name': normalizedName,
          'phone': normalizedPhone,
          'email': normalizedEmail,
          'address': address.trim(),
          'gender': gender.trim(),
        },
      );
      final remote = ProfileModel.fromJson(response);
      final profile = ProfileModel(
        id: remote.id,
        userId: remote.userId,
        role: remote.role,
        name: remote.name.isEmpty ? normalizedName : remote.name,
        phone: remote.phone.isEmpty ? normalizedPhone : remote.phone,
        email: remote.email.isEmpty ? normalizedEmail : remote.email,
        address: remote.address.isEmpty ? address.trim() : remote.address,
        gender: remote.gender.isEmpty ? gender.trim() : remote.gender,
        avatarPath: avatarPath.trim(),
        preferredRideType: remote.preferredRideType,
      );
      await _cache(profile);
      return Right(profile);
    } catch (error) {
      return Left(_mapFailure(error));
    }
  }

  Future<String> _passengerId() async {
    final passengerId = await _sessionService.readPassengerId() ?? '';
    if (passengerId.isEmpty) {
      throw CacheException(message: 'Passenger ID is not registered.');
    }
    return passengerId;
  }

  Future<void> _cache(ProfileModel profile) async {
    await Future.wait<void>([
      _preferences.setString('passenger_name', profile.name),
      _preferences.setString('passenger_phone', profile.phone),
      _preferences.setString('passenger_email', profile.email),
      _preferences.setString('passenger_address', profile.address),
      _preferences.setString('passenger_gender', profile.gender),
      _preferences.setString('passenger_avatar_path', profile.avatarPath),
    ]);
  }
}

Failure _mapFailure(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      return const AuthFailure(
        'Your passenger session has ended. Sign in again.',
      );
    }
    if (statusCode == 400 || statusCode == 422) {
      return const ValidationFailure('Profile values are invalid.');
    }
    if (statusCode == null) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return const ServerFailure.withStatusCode(
          'Profile request timed out.',
          504,
        );
      }
      return const NetworkFailure(
        'Unable to refresh your profile. Check your connection.',
      );
    }
    return ServerFailure.withStatusCode(
      'Your profile is temporarily unavailable.',
      statusCode,
    );
  }
  if (error is CacheException) return CacheFailure(error.message);
  if (error is ServerException) {
    return ServerFailure.withStatusCode(error.message, error.statusCode);
  }
  return const ServerFailure('Your profile is temporarily unavailable.');
}
