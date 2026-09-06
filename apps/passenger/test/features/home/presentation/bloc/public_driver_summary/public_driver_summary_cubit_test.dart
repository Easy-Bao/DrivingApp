import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/home/domain/entities/public_driver_summary.dart';
import 'package:passenger/src/features/home/domain/repositories/public_driver_summary_repository.dart';
import 'package:passenger/src/features/home/presentation/bloc/public_driver_summary/public_driver_summary_cubit.dart';
import 'package:passenger/src/features/home/presentation/bloc/public_driver_summary/public_driver_summary_state.dart';

class MockPublicDriverSummaryRepository extends Mock
    implements PublicDriverSummaryRepository {}

void main() {
  const summary = PublicDriverSummary(
    id: '42',
    name: 'Nearby Driver',
    vehicleType: 'Sedan',
    rating: 4.8,
  );

  blocTest<PublicDriverSummaryCubit, PublicDriverSummaryState>(
    'loads public summaries once for the guest home screen',
    build: () {
      final repository = MockPublicDriverSummaryRepository();
      when(() => repository.fetchSummaries()).thenAnswer(
        (_) async => const Right<Failure, List<PublicDriverSummary>>([summary]),
      );
      return PublicDriverSummaryCubit(repository: repository);
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.load();
    },
    expect: () => [
      const PublicDriverSummaryState(status: PublicDriverSummaryStatus.loading),
      const PublicDriverSummaryState(
        status: PublicDriverSummaryStatus.success,
        summaries: [summary],
      ),
    ],
  );

  test('allows a normal retry after a failed load', () async {
    final repository = MockPublicDriverSummaryRepository();
    when(() => repository.fetchSummaries()).thenAnswer(
      (_) async =>
          const Left<Failure, List<PublicDriverSummary>>(NetworkFailure()),
    );
    final cubit = PublicDriverSummaryCubit(repository: repository);

    await cubit.load();
    verify(() => repository.fetchSummaries()).called(1);

    when(() => repository.fetchSummaries()).thenAnswer(
      (_) async => const Right<Failure, List<PublicDriverSummary>>([summary]),
    );
    await cubit.load();

    expect(cubit.state.status, PublicDriverSummaryStatus.success);
    expect(cubit.state.summaries, [summary]);
    verify(() => repository.fetchSummaries()).called(1);
    await cubit.close();
  });

  test('shares one in-flight request between concurrent callers', () async {
    final repository = MockPublicDriverSummaryRepository();
    final response = Completer<Either<Failure, List<PublicDriverSummary>>>();
    when(() => repository.fetchSummaries()).thenAnswer((_) => response.future);
    final cubit = PublicDriverSummaryCubit(repository: repository);

    final first = cubit.load();
    final second = cubit.load();
    await Future<void>.delayed(Duration.zero);
    verify(() => repository.fetchSummaries()).called(1);

    response.complete(
      const Right<Failure, List<PublicDriverSummary>>([summary]),
    );
    await Future.wait([first, second]);
    expect(cubit.state.status, PublicDriverSummaryStatus.success);
    await cubit.close();
  });
}
