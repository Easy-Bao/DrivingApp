import 'package:bloc_test/bloc_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/home/presentation/bloc/public_driver_summary/public_driver_summary_cubit.dart';
import 'package:passenger/src/features/home/presentation/bloc/public_driver_summary/public_driver_summary_state.dart';
import 'package:passenger/src/features/home/domain/entities/public_driver_summary.dart';
import 'package:passenger/src/features/home/domain/repositories/public_driver_summary_repository.dart';
import 'package:foundation/foundation.dart';

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
}
