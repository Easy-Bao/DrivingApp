import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/profile/domain/entities/profile_model.dart';

abstract interface class PassengerProfileRepository {
  ProfileModel getCachedProfile();

  Future<Result<ProfileModel, Failure>> refreshProfile();

  Future<Result<ProfileModel, Failure>> updateProfile({
    required String name,
    required String phone,
    required String email,
    required String address,
    required String gender,
    required String avatarPath,
  });
}
