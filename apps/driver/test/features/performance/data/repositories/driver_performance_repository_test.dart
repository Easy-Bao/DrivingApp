import 'package:dio/dio.dart';
import 'package:driver/src/features/performance/data/data_sources/driver_performance_remote_data_source.dart';
import 'package:driver/src/features/performance/data/repositories/driver_performance_repository_impl.dart';
import 'package:driver/src/features/performance/domain/entities/driver_performance_stats.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:foundation/foundation.dart';

class MockDriverPerformanceRemoteDataSource extends Mock
    implements DriverPerformanceRemoteDataSource {}

void main() {
  late MockDriverPerformanceRemoteDataSource dataSource;
  late DriverPerformanceRepositoryImpl repository;

  setUp(() {
    dataSource = MockDriverPerformanceRemoteDataSource();
    repository = DriverPerformanceRepositoryImpl(dataSource: dataSource);
  });

  test('normalizes the complete driver statistics contract', () async {
    when(() => dataSource.fetchStats('42')).thenAnswer(
      (_) async => <String, dynamic>{
        'today_earnings_centavos': '2817',
        'today_completed_trips': 1,
        'total_trips': 6,
        'completed_trips': 5,
        'total_earnings_centavos': 14085,
        'average_rating': '4.8',
      },
    );

    final result = await repository.fetchStats('42');

    expect(
      result,
      const Right<Failure, DriverPerformanceStats>(
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
  });

  test('rejects fractional trip counts instead of truncating them', () async {
    when(() => dataSource.fetchStats('42')).thenAnswer(
      (_) async => <String, dynamic>{
        'today_earnings_centavos': 2817,
        'today_completed_trips': 1.5,
        'total_trips': 6,
        'completed_trips': 5,
        'total_earnings_centavos': 14085,
        'average_rating': 4.8,
      },
    );

    final result = await repository.fetchStats('42');

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<ValidationFailure>()),
      (_) => fail('Expected an invalid statistics response.'),
    );
  });

  test('maps an unreachable statistics API to a network failure', () async {
    when(() => dataSource.fetchStats('42')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/api/v1/drivers/42/stats'),
        type: DioExceptionType.connectionError,
      ),
    );

    final result = await repository.fetchStats('42');

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<NetworkFailure>()),
      (_) => fail('Expected a network failure.'),
    );
  });
}
