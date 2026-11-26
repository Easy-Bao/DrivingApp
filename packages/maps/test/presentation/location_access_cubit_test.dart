import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group(LocationAccessCubit, () {
    test('exposes unavailable access when the service is disabled', () async {
      final repository = _FakeLocationAccessRepository(
        LocationAccessState.serviceDisabled,
      );
      final cubit = LocationAccessCubit(repository: repository);
      addTearDown(cubit.close);

      final states = <LocationAccessViewState>[];
      final subscription = cubit.stream.listen(states.add);
      addTearDown(subscription.cancel);

      await cubit.start();
      await Future<void>.delayed(Duration.zero);

      expect(states, const [
        LocationAccessUnavailable(
          accessState: LocationAccessState.serviceDisabled,
          message:
              'Turn on device location in Settings, then return to EasyRide.',
        ),
      ]);
    });

    test('requests permission once when startup access is denied', () async {
      final repository = _FakeLocationAccessRepository(
        LocationAccessState.denied,
      )..permissionResult = LocationAccessState.ready;
      final cubit = LocationAccessCubit(repository: repository);
      addTearDown(cubit.close);

      final states = <LocationAccessViewState>[];
      final subscription = cubit.stream.listen(states.add);
      addTearDown(subscription.cancel);

      await cubit.start();
      await Future<void>.delayed(Duration.zero);

      expect(states, const [LocationAccessReady()]);
      expect(repository.permissionRequests, 1);
    });

    test(
      'does not request permission again on repeated startup checks',
      () async {
        final repository = _FakeLocationAccessRepository(
          LocationAccessState.denied,
        )..permissionResult = LocationAccessState.denied;
        final cubit = LocationAccessCubit(repository: repository);
        addTearDown(cubit.close);

        final states = <LocationAccessViewState>[];
        final subscription = cubit.stream.listen(states.add);
        addTearDown(subscription.cancel);

        await cubit.start();
        await cubit.start();
        await Future<void>.delayed(Duration.zero);

        expect(states, const [
          LocationAccessUnavailable(accessState: LocationAccessState.denied),
        ]);
        expect(repository.permissionRequests, 1);
      },
    );

    test('reacts when location is lost after becoming ready', () async {
      final repository = _FakeLocationAccessRepository(
        LocationAccessState.ready,
      );
      final cubit = LocationAccessCubit(repository: repository);
      addTearDown(cubit.close);

      final states = <LocationAccessViewState>[];
      final subscription = cubit.stream.listen(states.add);
      addTearDown(subscription.cancel);

      await cubit.start();
      repository.emit(LocationAccessState.serviceDisabled);
      await Future<void>.delayed(Duration.zero);

      expect(states, const [
        LocationAccessReady(),
        LocationAccessUnavailable(
          accessState: LocationAccessState.serviceDisabled,
          message:
              'Turn on device location in Settings, then return to EasyRide.',
        ),
      ]);
    });

    test('ignores late async results after close', () async {
      final startCompleter = Completer<LocationAccessState>();
      final repository = _FakeLocationAccessRepository(
        LocationAccessState.ready,
        startMonitoringOverride: () => startCompleter.future,
      );
      final cubit = LocationAccessCubit(repository: repository);

      final startFuture = cubit.start();
      await cubit.close();
      startCompleter.complete(LocationAccessState.ready);

      await expectLater(startFuture, completes);
    });
  });

  group(LocationAccessOverlayScope, () {
    testWidgets(
      'isolates child subtree from LocationAccessCubit state changes',
      (tester) async {
        final repository = _FakeLocationAccessRepository(
          LocationAccessState.serviceDisabled,
        );
        final cubit = LocationAccessCubit(repository: repository);
        addTearDown(cubit.close);
        var childBuildCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.main,
            home: BlocProvider<LocationAccessCubit>.value(
              value: cubit,
              child: LocationAccessOverlayScope(
                enabled: true,
                child: Builder(
                  builder: (_) {
                    childBuildCount++;
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        );

        expect(childBuildCount, 1);
        expect(find.byType(LocationAccessOverlay), findsOneWidget);

        await cubit.start();
        await tester.pump();
        expect(childBuildCount, 1);
        expect(find.byType(LocationAccessOverlay), findsOneWidget);

        repository.emit(LocationAccessState.ready);
        await tester.pump();
        expect(childBuildCount, 1);
        expect(find.byType(LocationAccessOverlay), findsNothing);
      },
    );
  });
}

class _FakeLocationAccessRepository implements LocationAccessRepository {
  _FakeLocationAccessRepository(
    this.currentAccessState, {
    this._startMonitoringOverride,
  });

  final StreamController<LocationAccessState> _changes =
      StreamController<LocationAccessState>.broadcast();
  final Future<LocationAccessState> Function()? _startMonitoringOverride;

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
  Future<LocationAccessState> startMonitoring() {
    final override = _startMonitoringOverride;
    if (override != null) return override();
    return Future<LocationAccessState>.value(currentAccessState);
  }

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
