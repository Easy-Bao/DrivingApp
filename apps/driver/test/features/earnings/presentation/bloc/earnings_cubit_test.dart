import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:driver/src/features/earnings/domain/entities/driver_earnings_summary.dart';
import 'package:driver/src/features/earnings/domain/repositories/driver_earnings_repository.dart';
import 'package:driver/src/features/earnings/presentation/bloc/earnings_cubit.dart';
import 'package:driver/src/features/earnings/presentation/bloc/earnings_state.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';

class _MockEarningsRepository extends Mock implements EarningsRepository {}

class _MockSessionService extends Mock implements SessionStore {}

void main() {
  late _MockEarningsRepository repository;
  late _MockSessionService sessionService;

  final testSummary = EarningsSummary.fromJson(const {
    'this_week': {'earnings_amount': 1200, 'completed_trips': 2},
  });

  setUp(() {
    repository = _MockEarningsRepository();
    sessionService = _MockSessionService();
    when(() => sessionService.readDriverId())
        .thenAnswer((_) async => 'driver-1');
  });

  blocTest<EarningsCubit, EarningsState>(
    'loads earnings through the repository boundary',
    build: () {
      when(() => repository.fetchEarningsSummary('driver-1'))
          .thenAnswer((_) async => Ok(testSummary));
      return EarningsCubit(
        repository: repository,
        sessionService: sessionService,
      );
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const EarningsState(isLoading: true),
      isA<EarningsState>()
          .having((state) => state.isLoading, 'isLoading', isFalse)
          .having((state) => state.data, 'data', testSummary),
    ],
  );

  test(
    'ignores an overlapping load while the first request is active',
    () async {
      final response = Completer<Result<EarningsSummary, Failure>>();
      when(() => repository.fetchEarningsSummary('driver-1'))
          .thenAnswer((_) => response.future);
      final cubit = EarningsCubit(
        repository: repository,
        sessionService: sessionService,
      );

      final first = cubit.load();
      await Future<void>.delayed(Duration.zero);
      final second = cubit.load();
      response.complete(Ok(testSummary));
      await Future.wait([first, second]);

      verify(() => repository.fetchEarningsSummary('driver-1')).called(1);
      await cubit.close();
    },
  );

  test('preserves cached earnings when a refresh fails', () async {
    final responses = <Result<EarningsSummary, Failure>>[
      Ok(testSummary),
      const Err(NetworkFailure()),
    ];
    when(() => repository.fetchEarningsSummary('driver-1'))
        .thenAnswer((_) async => responses.removeAt(0));
    final cubit = EarningsCubit(
      repository: repository,
      sessionService: sessionService,
    );

    await cubit.load();
    await cubit.load();

    expect(cubit.state.data, testSummary);
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.errorMessage, isNotNull);
    await cubit.close();
  });
}
