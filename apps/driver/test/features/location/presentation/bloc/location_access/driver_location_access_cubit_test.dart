import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:driver/src/features/location/presentation/bloc/location_access/driver_location_access_cubit.dart';
import 'package:driver/src/features/location/presentation/bloc/location_access/driver_location_access_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';

void main() {
  group(LocationAccessCubit, () {
    late _FakeLocationAccessRepository repository;

    blocTest<LocationAccessCubit, LocationAccessViewState>(
      'exposes unavailable access when the service is disabled',
      build: () {
        repository = _FakeLocationAccessRepository(
          LocationAccessState.serviceDisabled,
        );
        return LocationAccessCubit(repository: repository);
      },
      act: (cubit) => cubit.start(),
      expect: () => const [
        LocationAccessUnavailable(
          accessState: LocationAccessState.serviceDisabled,
          message:
              'Turn on device location in Settings, then return to EasyRide.',
        ),
      ],
    );

    blocTest<LocationAccessCubit, LocationAccessViewState>(
      'requests permission once when startup access is denied',
      build: () {
        repository = _FakeLocationAccessRepository(LocationAccessState.denied)
          ..permissionResult = LocationAccessState.ready;
        return LocationAccessCubit(repository: repository);
      },
      act: (cubit) => cubit.start(),
      expect: () => const [LocationAccessReady()],
      verify: (_) => expect(repository.permissionRequests, 1),
    );

    blocTest<LocationAccessCubit, LocationAccessViewState>(
      'reacts when location is lost after becoming ready',
      build: () {
        repository = _FakeLocationAccessRepository(LocationAccessState.ready);
        return LocationAccessCubit(repository: repository);
      },
      act: (cubit) async {
        await cubit.start();
        repository.emit(LocationAccessState.serviceDisabled);
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => const [
        LocationAccessReady(),
        LocationAccessUnavailable(
          accessState: LocationAccessState.serviceDisabled,
          message:
              'Turn on device location in Settings, then return to EasyRide.',
        ),
      ],
    );
  });
}

class _FakeLocationAccessRepository(this.currentAccessState)
    implements LocationAccessRepository {
  final StreamController<LocationAccessState> _changes =
      StreamController<LocationAccessState>.broadcast();

  LocationAccessState currentAccessState;
  LocationAccessState permissionResult = LocationAccessState.denied;
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
