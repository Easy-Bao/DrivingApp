import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/profile/domain/entities/profile.dart';

abstract interface class ProfileRepository {
  Profile getCachedProfile();

  Future<Result<Profile, Failure>> refreshProfile();

  Future<Result<Profile, Failure>> updateProfile({
    required String name,
    required String address,
    required String gender,
    required String avatarPath,
  });
}
