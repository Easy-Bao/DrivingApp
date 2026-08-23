import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/home/data/datasources/public_driver_remote_data_source.dart';
import 'package:passenger_app/src/features/home/data/repositories/public_driver_summary_repository.dart';
import 'package:passenger_app/src/features/home/domain/entities/public_driver_summary.dart';
import 'package:shared_core/shared_core.dart';

class MockPublicDriverRemoteDataSource extends Mock
    implements PublicDriverRemoteDataSource {}

void main() {
  test('maps only the safe public driver summary fields', () async {
    final dataSource = MockPublicDriverRemoteDataSource();
    when(() => dataSource.fetchSummaries()).thenAnswer(
      (_) async => [
        {
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

    final result = await PublicDriverSummaryRepository(
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
