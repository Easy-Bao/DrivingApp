import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/home/data/data_sources/public_driver_remote_data_source.dart';
import 'package:passenger/src/features/home/data/repositories/public_driver_summary_repository_impl.dart';
import 'package:passenger/src/features/home/domain/entities/public_driver_summary.dart';

class MockPublicDriverRemoteDataSource extends Mock
    implements PublicDriverRemoteDataSource {}

void main() {
  test('maps only the safe public driver summary fields', () async {
    final dataSource = MockPublicDriverRemoteDataSource();
    when(() => dataSource.fetchSummaries()).thenAnswer(
      (_) async => [
        <String, dynamic>{
          'id': 42,
          'name': 'Nearby Driver',
          'vehicle_type': 'Sedan',
          'rating': 4.8,
          'plate_number': 'ABC 1234',
          'latitude': 7.828,
          'longitude': 123.434,
        },
      ],
    );

    final result = await PublicDriverSummaryRepositoryImpl(
      remoteDataSource: dataSource,
    ).fetchSummaries();

    expect(result, isA<Right<Failure, List<PublicDriverSummary>>>());
    final summaries = result.getOrElse((_) => const []);
    expect(summaries, hasLength(1));
    expect(summaries.single.id, '42');
    expect(summaries.single.name, 'Nearby Driver');
    expect(summaries.single.vehicleType, 'Sedan');
    expect(summaries.single.rating, 4.8);
    verify(() => dataSource.fetchSummaries()).called(1);
  });
}
