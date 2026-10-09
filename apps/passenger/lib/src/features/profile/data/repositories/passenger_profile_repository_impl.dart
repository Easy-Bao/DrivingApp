import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/auth/domain/failures/auth_failures.dart';
import 'package:passenger/src/features/profile/data/data_sources/passenger_profile_remote_data_source.dart';
import 'package:passenger/src/features/profile/domain/entities/passenger_profile.dart';
import 'package:passenger/src/features/profile/domain/repositories/passenger_profile_repository.dart';
import 'package:passenger/src/infrastructure/session/passenger_session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class PassengerProfileRepositoryImpl
    implements PassengerProfileRepository {
  PassengerProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.sessionService,
    required this.preferences,
  });

  final PassengerProfileRemoteDataSource remoteDataSource;
  final PassengerSessionStore sessionService;
  final SharedPreferences preferences;
  String _avatarData = '';

  @override
  PassengerProfile getCachedProfile() {
    return PassengerProfile(
      name: preferences.getString('passenger_name') ?? '',
      phone: preferences.getString('passenger_phone') ?? '',
      email: preferences.getString('passenger_email') ?? '',
      address: preferences.getString('passenger_address') ?? '',
      gender: preferences.getString('passenger_gender') ?? '',
      avatarPath: preferences.getString('passenger_avatar_path') ?? '',
      avatarData: _avatarData,
    );
  }

  @override
  Future<Result<PassengerProfile, Failure>> refreshProfile() async {
    try {
      final passengerId = await _passengerId();
      final cached = getCachedProfile();
      final remote = PassengerProfile.fromJson(
        await remoteDataSource.fetchProfile(passengerId),
      );
      var avatarData = _avatarData;
      if (remote.avatarUrl.isEmpty) {
        avatarData = '';
      } else {
        try {
          final bytes = await remoteDataSource.fetchProfileAvatar(passengerId);
          avatarData = bytes.isEmpty ? '' : base64Encode(bytes);
        } catch (_) {
          // A profile should remain usable when its optional photo is unavailable.
        }
      }
      _avatarData = avatarData;
      final remoteName = remote.name.trim();
      final cachedName = cached.name.trim();
      final resolvedName = remoteName.isNotEmpty && !remoteName.contains('@')
          ? remoteName
          : (cachedName.isNotEmpty && !cachedName.contains('@')
                ? cachedName
                : (remoteName.isNotEmpty ? remoteName : cachedName));
      final profile = PassengerProfile(
        id: remote.id,
        userId: remote.userId,
        role: remote.role,
        name: resolvedName,
        phone: remote.phone.isEmpty ? cached.phone : remote.phone,
        email: remote.email.isEmpty ? cached.email : remote.email,
        address: remote.address.isEmpty ? cached.address : remote.address,
        gender: remote.gender.isEmpty ? cached.gender : remote.gender,
        avatarPath: cached.avatarPath,
        avatarUrl: remote.avatarUrl,
        avatarData: avatarData,
        preferredRideType: remote.preferredRideType,
      );
      await _cache(profile);
      return Ok(profile);
    } catch (error) {
      return Err(_mapFailure(error));
    }
  }

  @override
  Future<Result<PassengerProfile, Failure>> updateProfile({
    required String name,
    required String address,
    required String gender,
    required String avatarPath,
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      return const Err(ValidationFailure('Profile values are invalid.'));
    }
    try {
      final passengerId = await _passengerId();
      final cached = getCachedProfile();
      final normalizedAvatarPath = avatarPath.trim();
      var avatarData = _avatarData;
      if (normalizedAvatarPath.isNotEmpty &&
          normalizedAvatarPath != cached.avatarPath) {
        final bytes = await File(normalizedAvatarPath).readAsBytes();
        if (bytes.isEmpty || bytes.length > (2 << 20)) {
          return const Err(
            ValidationFailure('Choose a profile photo under 2 MB.'),
          );
        }
        await remoteDataSource.uploadProfileAvatar(
          passengerId: passengerId,
          bytes: bytes,
          fileName: _avatarFileName(normalizedAvatarPath),
        );
        avatarData = base64Encode(bytes);
      }
      final response = await remoteDataSource.updateProfile(
        passengerId: passengerId,
        data: {
          'name': normalizedName,
          'address': address.trim(),
          'gender': gender.trim(),
        },
      );
      final remote = PassengerProfile.fromJson(response);
      if (normalizedAvatarPath == cached.avatarPath &&
          remote.avatarUrl.isNotEmpty) {
        try {
          final bytes = await remoteDataSource.fetchProfileAvatar(passengerId);
          avatarData = bytes.isEmpty ? '' : base64Encode(bytes);
        } catch (_) {
          // Keep the last usable in-memory image when a refresh is transient.
        }
      } else if (remote.avatarUrl.isEmpty) {
        avatarData = '';
      }
      _avatarData = avatarData;
      final profile = PassengerProfile(
        id: remote.id,
        userId: remote.userId,
        role: remote.role,
        name: remote.name.isEmpty ? normalizedName : remote.name,
        phone: remote.phone.isEmpty ? cached.phone : remote.phone,
        email: remote.email.isEmpty ? cached.email : remote.email,
        address: remote.address.isEmpty ? address.trim() : remote.address,
        gender: remote.gender.isEmpty ? gender.trim() : remote.gender,
        avatarPath: normalizedAvatarPath,
        avatarUrl: remote.avatarUrl,
        avatarData: avatarData,
        preferredRideType: remote.preferredRideType,
      );
      await _cache(profile);
      return Ok(profile);
    } catch (error) {
      return Err(_mapFailure(error));
    }
  }

  Future<String> _passengerId() async {
    final passengerId = await sessionService.readPassengerId() ?? '';
    if (passengerId.isEmpty) {
      throw CacheException(message: 'Passenger ID is not registered.');
    }
    return passengerId;
  }

  Future<void> _cache(PassengerProfile profile) async {
    await Future.wait<void>([
      preferences.setString('passenger_name', profile.name),
      preferences.setString('passenger_phone', profile.phone),
      preferences.setString('passenger_email', profile.email),
      preferences.setString('passenger_address', profile.address),
      preferences.setString('passenger_gender', profile.gender),
      preferences.setString('passenger_avatar_path', profile.avatarPath),
    ]);
  }

  String _avatarFileName(String path) {
    final fileName = path.split(RegExp(r'[/\\]')).last.trim();
    return fileName.isEmpty ? 'profile.jpg' : fileName;
  }
}

Failure _mapFailure(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401) {
      return const AuthFailure(
        'Your passenger session has ended. Sign in again.',
      );
    }
    if (statusCode == 403) {
      return const ServerFailure.withStatusCode(
        'You do not have permission to view or update your profile.',
        403,
      );
    }
    if (statusCode == 413) {
      return const ValidationFailure('Choose a profile photo under 2 MB.');
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
  if (error is CacheException) {
    return const CacheFailure(
      'Saved profile information is unavailable. Please try again.',
    );
  }
  if (error is ServerException) {
    if (error.statusCode == 401) {
      return const AuthFailure(
        'Your passenger session has ended. Sign in again.',
      );
    }
    if (error.statusCode == 403) {
      return const ServerFailure.withStatusCode(
        'You do not have permission to view or update your profile.',
        403,
      );
    }
    if (error.statusCode == 400 || error.statusCode == 422) {
      return const ValidationFailure('Profile values are invalid.');
    }
    return ServerFailure.withStatusCode(
      'Your profile is temporarily unavailable.',
      error.statusCode,
    );
  }
  return const ServerFailure('Your profile is temporarily unavailable.');
}
