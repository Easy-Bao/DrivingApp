import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:driver/src/features/performance/domain/entities/driver_performance_stats.dart';
import 'package:driver/src/features/performance/domain/repositories/driver_performance_repository.dart';
import 'package:driver/src/features/performance/presentation/bloc/driver_performance_cubit.dart';
import 'package:driver/src/features/performance/presentation/bloc/driver_performance_state.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';

class _MockPerformanceRepository extends Mock
    implements DriverPerformanceRepository {}

class _MockSessionService extends Mock implements DriverSessionStore {}

void main() {
  late _MockPerformanceRepository repository;
  late _MockSessionService sessionService;

  setUp(() {
    repository = _MockPerformanceRepository();
    sessionService = _MockSessionService();
    when(() => sessionService.readDriverId())
        .thenAnswer((_) async => 'driver-1');
  });

  blocTest<DriverPerformanceCubit, DriverPerformanceState>(
    'loads performance statistics independently from profile data',
    build: () {
      when(() => repository.fetchStats('driver-1')).thenAnswer(
        (_) async => const Right(
          DriverPerformanceStats(
            todayEarningsCentavos: 2817,
            todayCompletedTrips: 1,
            totalTrips: 6,
            completedTrips: 5,
            totalEarningsCentavos: 14085,
            averageRating: 4.8,
          ),
        ),
      );
      return DriverPerformanceCubit(
        repository: repository,
        sessionService: sessionService,
      );
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<DriverPerformanceLoading>(),
      isA<DriverPerformanceLoaded>()
          .having((state) => state.isLoading, 'isLoading', isFalse)
          .having((state) => state.stats.completedTrips, 'completed trips', 5),
    ],
  );

  test(
    'ignores an overlapping load while the first request is active',
    () async {
      final response = Completer<Either<Failure, DriverPerformanceStats>>();
      when(() => repository.fetchStats('driver-1'))
          .thenAnswer((_) => response.future);
      final cubit = DriverPerformanceCubit(
        repository: repository,
        sessionService: sessionService,
      );

      final first = cubit.load();
      await Future<void>.delayed(Duration.zero);
      final second = cubit.load();
      response.complete(
        const Right(
          DriverPerformanceStats(
            todayEarningsCentavos: 100,
            todayCompletedTrips: 1,
            totalTrips: 1,
            completedTrips: 1,
            totalEarningsCentavos: 100,
            averageRating: 5,
          ),
        ),
      );
      await Future.wait([first, second]);

      verify(() => repository.fetchStats('driver-1')).called(1);
      await cubit.close();
    },
  );
}
