import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:maps/maps.dart';
import 'package:driver_app/src/features/location/presentation/bloc/location_access/driver_location_access_cubit.dart';
import 'package:driver_app/src/features/location/presentation/bloc/location_access/driver_location_access_state.dart';
import 'package:driver_app/src/features/location/domain/repositories/i_driver_location_access_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(DriverLocationAccessCubit, () {
    late _FakeDriverLocationAccessRepository repository;

    blocTest<DriverLocationAccessCubit, DriverLocationAccessViewState>(
      'exposes unavailable access when the service is disabled',
      build: () {
        repository = _FakeDriverLocationAccessRepository(
          LocationAccessState.serviceDisabled,
        );
        return DriverLocationAccessCubit(repository: repository);
      },
      act: (cubit) => cubit.start(),
      expect: () => const [
        DriverLocationAccessUnavailable(
          accessState: LocationAccessState.serviceDisabled,
          message:
              'Turn on device location in Settings, then return to BaoRide.',
        ),
      ],
    );

    blocTest<DriverLocationAccessCubit, DriverLocationAccessViewState>(
      'requests permission once when startup access is denied',
      build: () {
        repository = _FakeDriverLocationAccessRepository(
          LocationAccessState.denied,
        )..permissionResult = LocationAccessState.ready;
        return DriverLocationAccessCubit(repository: repository);
      },
      act: (cubit) => cubit.start(),
      expect: () => const [DriverLocationAccessReady()],
      verify: (_) => expect(repository.permissionRequests, 1),
    );

    blocTest<DriverLocationAccessCubit, DriverLocationAccessViewState>(
      'reacts when location is lost after becoming ready',
      build: () {
        repository = _FakeDriverLocationAccessRepository(
          LocationAccessState.ready,
        );
        return DriverLocationAccessCubit(repository: repository);
      },
      act: (cubit) async {
        await cubit.start();
        repository.emit(LocationAccessState.serviceDisabled);
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => const [
        DriverLocationAccessReady(),
        DriverLocationAccessUnavailable(
          accessState: LocationAccessState.serviceDisabled,
          message:
              'Turn on device location in Settings, then return to BaoRide.',
        ),
      ],
    );
  });
}

class _FakeDriverLocationAccessRepository
    implements IDriverLocationAccessRepository {
  _FakeDriverLocationAccessRepository(this.currentAccessState);

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
