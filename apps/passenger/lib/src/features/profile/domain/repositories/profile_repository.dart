import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/profile/domain/entities/profile.dart';

abstract interface class ProfileRepository {
  static const int maxAvatarBytes = 2 << 20;

  Profile getCachedProfile();

  void clearCachedProfile();

  Future<Result<Profile, Failure>> refreshProfile();

  Future<Result<Profile, Failure>> updateProfile({
    required String name,
    required String address,
    required String gender,
    required String avatarPath,
  });
}
