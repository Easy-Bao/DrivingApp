import 'package:bloc_test/bloc_test.dart';
import 'package:driver_app/src/features/earnings/domain/repositories/driver_earnings_repository.dart';
import 'package:driver_app/src/features/earnings/presentation/bloc/earnings_cubit.dart';
import 'package:driver_app/src/features/earnings/presentation/bloc/earnings_state.dart';
import 'package:driver_app/src/infrastructure/session/driver_session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockEarningsRepository extends Mock
    implements DriverEarningsRepository {}

class _MockSessionService extends Mock implements DriverSessionStore {}

void main() {
  late _MockEarningsRepository repository;
  late _MockSessionService sessionService;

  setUp(() {
    repository = _MockEarningsRepository();
    sessionService = _MockSessionService();
    when(() => sessionService.readDriverId())
        .thenAnswer((_) async => 'driver-1');
  });

  blocTest<DriverEarningsCubit, DriverEarningsState>(
    'loads earnings through the repository boundary',
    build: () {
      when(() => repository.fetchEarningsSummary('driver-1'))
          .thenAnswer((_) async => const Right({'this_week': {}}));
      return DriverEarningsCubit(
        repository: repository,
        sessionService: sessionService,
      );
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      const DriverEarningsState(isLoading: true),
      isA<DriverEarningsState>()
          .having((state) => state.isLoading, 'isLoading', isFalse)
          .having((state) => state.data, 'data', {'this_week': {}}),
    ],
  );
}
