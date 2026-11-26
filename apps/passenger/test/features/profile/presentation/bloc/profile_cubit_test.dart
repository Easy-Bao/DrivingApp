import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/profile/domain/entities/profile.dart';
import 'package:passenger/src/features/profile/domain/repositories/profile_repository.dart';
import 'package:passenger/src/features/profile/presentation/bloc/profile_cubit.dart';

class _FakeProfileRepository implements ProfileRepository {
  Completer<Result<Profile, Failure>>? refreshCompleter;
  bool cleared = false;

  Profile cached = const Profile(
    name: 'Cached Passenger',
    phone: '+63 900 000 0000',
    email: 'cached@example.com',
    address: 'Cached address',
    gender: 'Prefer not to say',
  );
  Profile remote = const Profile(
    name: 'Remote Passenger',
    phone: '+63 911 111 1111',
    email: 'remote@example.com',
    address: 'Remote address',
    gender: 'Female',
  );

  @override
  Profile getCachedProfile() => cached;

  @override
  void clearCachedProfile() {
    cleared = true;
    cached = const Profile();
  }

  @override
  Future<Result<Profile, Failure>> refreshProfile() async {
    final completer = refreshCompleter;
    if (completer != null) {
      return completer.future;
    }
    cached = remote;
    return Ok(remote);
  }

  @override
  Future<Result<Profile, Failure>> updateProfile({
    required String name,
    required String address,
    required String gender,
    required String avatarPath,
  }) async {
    cached = Profile(
      name: name,
      phone: cached.phone,
      email: cached.email,
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
      address: 'Updated address',
      gender: 'Male',
      avatarPath: '',
    );

    expect(saved, isTrue);
    expect(cubit.state.name, 'Updated Passenger');
    expect(cubit.state.phone, '+63 911 111 1111');
    expect(cubit.state.email, 'remote@example.com');
    expect(cubit.state.address, 'Updated address');
    expect(cubit.state.gender, 'Male');
    expect(cubit.state.isSaving, isFalse);
    await cubit.close();
  });

  test('keeps isLoading true during remote refresh and ignores stale results after reset', () async {
    final repository = _FakeProfileRepository()
      ..refreshCompleter = Completer<Result<Profile, Failure>>();
    final cubit = ProfileCubit(repository: repository);

    final loadFuture = cubit.loadProfile();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.name, 'Cached Passenger');
    expect(cubit.state.isLoading, isTrue);

    cubit.reset();
    expect(repository.cleared, isTrue);
    expect(cubit.state, const ProfileState());

    repository.refreshCompleter!.complete(Ok(repository.remote));
    await loadFuture;

    expect(cubit.state, const ProfileState());
    await cubit.close();
  });
}
