import 'package:passenger_app/src/features/profile/domain/entities/profile_model.dart';
import 'package:fpdart/fpdart.dart';
import 'package:foundation/foundation.dart';

abstract interface class PassengerProfileRepository {
  ProfileModel getCachedProfile();

  Future<Either<Failure, ProfileModel>> refreshProfile();

  Future<Either<Failure, ProfileModel>> updateProfile({
    required String name,
    required String phone,
    required String email,
    required String address,
    required String gender,
    required String avatarPath,
  });
}
