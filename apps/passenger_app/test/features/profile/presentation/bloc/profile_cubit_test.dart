import 'package:passenger_app/src/features/profile/domain/entities/profile_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/profile/presentation/bloc/profile/profile_cubit.dart';
import 'package:passenger_app/src/features/profile/domain/repositories/i_passenger_profile_repository.dart';
import 'package:foundation/foundation.dart';

class _FakeProfileRepository implements IPassengerProfileRepository {
  ProfileModel cached = const ProfileModel(
    name: 'Cached Passenger',
    phone: '+63 900 000 0000',
    email: 'cached@example.com',
    address: 'Cached address',
    gender: 'Prefer not to say',
  );
  ProfileModel remote = const ProfileModel(
    name: 'Remote Passenger',
    phone: '+63 911 111 1111',
    email: 'remote@example.com',
    address: 'Remote address',
    gender: 'Female',
  );

  @override
  ProfileModel getCachedProfile() => cached;

  @override
  Future<Either<Failure, ProfileModel>> refreshProfile() async {
    cached = remote;
    return Right(remote);
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
    cached = ProfileModel(
      name: name,
      phone: phone,
      email: email,
      address: address,
      gender: gender,
      avatarPath: avatarPath,
    );
    return Right(cached);
  }
}

void main() {
  test('loads address data and saves edits through ProfileCubit', () async {
    final repository = _FakeProfileRepository();
    final cubit = ProfileCubit(repository: repository);

    await cubit.loadProfile();
    expect(cubit.state.address, 'Remote address');

    final saved = await cubit.updateProfile(
      name: 'Updated Passenger',
      phone: '+63 922 222 2222',
      email: 'updated@example.com',
      address: 'Updated address',
      gender: 'Male',
      avatarPath: '',
    );

    expect(saved, isTrue);
    expect(cubit.state.name, 'Updated Passenger');
    expect(cubit.state.address, 'Updated address');
    expect(cubit.state.gender, 'Male');
    expect(cubit.state.isSaving, isFalse);
    await cubit.close();
  });
}
