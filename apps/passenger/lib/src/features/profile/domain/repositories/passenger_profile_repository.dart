import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/profile/domain/entities/passenger_profile.dart';

abstract interface class PassengerProfileRepository {
  PassengerProfile getCachedProfile();

  Future<Result<PassengerProfile, Failure>> refreshProfile();

  Future<Result<PassengerProfile, Failure>> updateProfile({
    required String name,
    required String address,
    required String gender,
    required String avatarPath,
  });
}
