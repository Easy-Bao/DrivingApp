import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/profile/domain/entities/passenger_profile.dart';
import 'package:passenger/src/features/profile/domain/repositories/passenger_profile_repository.dart';
import 'package:passenger/src/features/profile/presentation/bloc/profile/profile_cubit.dart';

class _FakeProfileRepository implements PassengerProfileRepository {
  PassengerProfile cached = const PassengerProfile(
    name: 'Cached Passenger',
    phone: '+63 900 000 0000',
    email: 'cached@example.com',
    address: 'Cached address',
    gender: 'Prefer not to say',
  );
  PassengerProfile remote = const PassengerProfile(
    name: 'Remote Passenger',
    phone: '+63 911 111 1111',
    email: 'remote@example.com',
    address: 'Remote address',
    gender: 'Female',
  );

  @override
  PassengerProfile getCachedProfile() => cached;

  @override
  Future<Result<PassengerProfile, Failure>> refreshProfile() async {
    cached = remote;
    return Ok(remote);
  }

  @override
  Future<Result<PassengerProfile, Failure>> updateProfile({
    required String name,
    required String phone,
    required String email,
    required String address,
    required String gender,
    required String avatarPath,
  }) async {
    cached = PassengerProfile(
      name: name,
      phone: phone,
      email: email,
      address: address,
      gender: gender,
      avatarPath: avatarPath,
    );
    return Ok(cached);
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
