import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/booking/domain/entities/driver.dart';
import 'package:passenger/src/features/booking/domain/repositories/driver_repository.dart';
import 'package:passenger/src/features/booking/presentation/bloc/nearby_drivers/nearby_drivers_cubit.dart';

class _DriverRepository extends Mock implements DriverRepository {}

const _near = Driver(
  id: 'near',
  name: 'Nearby driver',
  vehicleType: 'Tricycle',
  plateNumber: 'ABC 123',
  rating: 4.8,
  lat: 14.6,
  lng: 120.9,
  distanceKm: 0.3,
  etaMinutes: 2,
  score: 1,
);
const _far = Driver(
  id: 'far',
  name: 'Other driver',
  vehicleType: 'Tricycle',
  plateNumber: 'ABC 456',
  rating: 4.7,
  lat: 14.6,
  lng: 120.9,
  distanceKm: 0.8,
  etaMinutes: 4,
  score: 1,
);

void main() {
  late _DriverRepository repository;
  late AppLifecycleCoordinator lifecycle;
  late NearbyDriversCubit cubit;
  setUp(() {
    repository = _DriverRepository();
    lifecycle = AppLifecycleCoordinator();
    when(() => repository.getNearbyDrivers(lat: 14.6, lng: 120.9))
        .thenAnswer((_) async => const Ok([_far, _near, _near]));
    cubit = NearbyDriversCubit(
      repository: repository,
      lifecycleCoordinator: lifecycle,
      latitude: 14.6,
      longitude: 120.9,
    );
  });
  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
    await lifecycle.dispose();
  });

  test(
    'loads available drivers before any fare response, sorted and deduplicated',
    () async {
      await cubit.refresh();
      expect(cubit.state.drivers, [_near, _far]);
      expect(cubit.state.hasLoaded, isTrue);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.errorMessage, isNull);
    },
  );

  test(
    'keeps previous availability when refresh fails, then permits retry',
    () async {
      await cubit.refresh();
      when(() => repository.getNearbyDrivers(lat: 14.6, lng: 120.9))
          .thenAnswer((_) async => const Err(NetworkFailure()));
      await cubit.refresh();
      expect(cubit.state.drivers, [_near, _far]);
      expect(cubit.state.errorMessage, isNotNull);
      when(() => repository.getNearbyDrivers(lat: 14.6, lng: 120.9))
          .thenAnswer((_) async => const Ok(<Driver>[]));
      await cubit.refresh();
      expect(cubit.state.drivers, isEmpty);
      expect(cubit.state.hasLoaded, isTrue);
      expect(cubit.state.errorMessage, isNull);
    },
  );

  test(
    'does not duplicate an in-flight lookup or emit after closing',
    () async {
      final response = Completer<Result<List<Driver>, Failure>>();
      when(() => repository.getNearbyDrivers(lat: 14.6, lng: 120.9))
          .thenAnswer((_) => response.future);
      final first = cubit.refresh();
      await cubit.refresh();
      verify(() => repository.getNearbyDrivers(lat: 14.6, lng: 120.9))
          .called(1);
      await cubit.close();
      response.complete(const Ok([_near]));
      await first;
      expect(cubit.state.drivers, isEmpty);
    },
  );

  testWidgets(
    'keeps polling after an empty result and discovers a driver later',
    (tester) async {
      var requests = 0;
      when(() => repository.getNearbyDrivers(lat: 14.6, lng: 120.9))
          .thenAnswer((_) async {
            requests++;
            return requests < 3 ? const Ok(<Driver>[]) : const Ok([_near]);
          });
      cubit.start();
      await tester.pump();
      expect(requests, 1);
      expect(cubit.state.drivers, isEmpty);
      await tester.pump(const Duration(seconds: 10));
      expect(requests, 2);
      await tester.pump(const Duration(seconds: 10));
      expect(requests, 3);
      expect(cubit.state.drivers, [_near]);
      await tester.runAsync(cubit.close);
    },
  );

  test('refreshes only while the search screen is in the foreground', () async {
    cubit.start();
    await Future<void>.delayed(Duration.zero);
    verify(() => repository.getNearbyDrivers(lat: 14.6, lng: 120.9)).called(1);
    lifecycle.update(isForeground: false);
    await cubit.refresh();
    verifyNever(() => repository.getNearbyDrivers(lat: 14.6, lng: 120.9));
    lifecycle.update(isForeground: true);
    await Future<void>.delayed(Duration.zero);
    verify(() => repository.getNearbyDrivers(lat: 14.6, lng: 120.9)).called(1);
    await cubit.close();
    await cubit.refresh();
    verifyNever(() => repository.getNearbyDrivers(lat: 14.6, lng: 120.9));
  });
}
