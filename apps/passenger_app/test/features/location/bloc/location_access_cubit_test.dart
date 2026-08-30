import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/core/location/location.dart';
import 'package:passenger_app/src/features/location/bloc/location_access/location_access_cubit.dart';
import 'package:passenger_app/src/features/location/bloc/location_access/location_access_state.dart';
import 'package:passenger_app/src/features/location/domain/repositories/i_location_access_repository.dart';

void main() {
  group(LocationAccessCubit, () {
    late _FakeLocationAccessRepository repository;

    blocTest<LocationAccessCubit, LocationAccessViewState>(
      'exposes the location prompt when initial access is denied',
      build: () {
        repository = _FakeLocationAccessRepository(.denied);
        return LocationAccessCubit(repository: repository);
      },
      act: (cubit) => cubit.start(),
      expect: () => const [LocationAccessUnavailable(accessState: .denied)],
    );

    blocTest<LocationAccessCubit, LocationAccessViewState>(
      'reacts when device location is switched off after being ready',
      build: () {
        repository = _FakeLocationAccessRepository(.ready);
        return LocationAccessCubit(repository: repository);
      },
      act: (cubit) async {
        await cubit.start();
        repository.emit(.serviceDisabled);
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => const [
        LocationAccessReady(),
        LocationAccessUnavailable(
          accessState: .serviceDisabled,
          message:
              'Turn on device location in Settings, then return to EasyRide.',
        ),
      ],
    );

    blocTest<LocationAccessCubit, LocationAccessViewState>(
      'requests permission once when startup access is denied',
      build: () {
        repository = _FakeLocationAccessRepository(.denied)
          ..permissionResult = .ready;
        return LocationAccessCubit(repository: repository);
      },
      act: (cubit) => cubit.start(),
      expect: () => const [LocationAccessReady()],
      verify: (_) => expect(repository.permissionRequests, 1),
    );

    blocTest<LocationAccessCubit, LocationAccessViewState>(
      'does not request permission again on repeated startup checks',
      build: () {
        repository = _FakeLocationAccessRepository(.denied)
          ..permissionResult = .denied;
        return LocationAccessCubit(repository: repository);
      },
      act: (cubit) async {
        await cubit.start();
        await cubit.start();
      },
      expect: () => const [LocationAccessUnavailable(accessState: .denied)],
      verify: (_) => expect(repository.permissionRequests, 1),
    );
  });
}

class _FakeLocationAccessRepository implements ILocationAccessRepository {
  _FakeLocationAccessRepository(this.currentAccessState);

  final StreamController<LocationAccessState> _changes =
      StreamController<LocationAccessState>.broadcast();

  LocationAccessState currentAccessState;
  LocationAccessState permissionResult = .denied;
  int permissionRequests = 0;

  @override
  Stream<LocationAccessState> get accessStateChanges => _changes.stream;

  void emit(LocationAccessState accessState) {
    currentAccessState = accessState;
    _changes.add(accessState);
  }

  @override
  Future<LocationAccessState> startMonitoring() async => currentAccessState;

  @override
  Future<LocationAccessState> refresh() async => currentAccessState;

  @override
  Future<LocationAccessState> requestPermission() async {
    permissionRequests++;
    currentAccessState = permissionResult;
    return currentAccessState;
  }

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;

  @override
  Future<void> dispose() => _changes.close();
}
