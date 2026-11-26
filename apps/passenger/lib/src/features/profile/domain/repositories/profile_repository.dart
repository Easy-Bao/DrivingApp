import 'package:core_domain/core_domain.dart';
import 'package:foundation/foundation.dart';

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
