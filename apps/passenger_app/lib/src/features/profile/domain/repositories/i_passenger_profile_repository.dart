import 'package:fpdart/fpdart.dart';
import 'package:shared_core/shared_core.dart';

abstract class IPassengerProfileRepository {
  ProfileModel getCachedProfile();

  Future<Either<Failure, ProfileModel>> refreshProfile();

  Future<Either<Failure, ProfileModel>> updateProfile({
    required String name,
    required String phone,
    required String email,
    required String address,
  });
}
