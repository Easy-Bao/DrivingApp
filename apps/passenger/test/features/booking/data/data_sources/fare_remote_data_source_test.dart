import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/booking/data/data_sources/fare_remote_data_source.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  test('requests fare estimates from the canonical fares route', () async {
    final dio = _MockDio();
    final dataSource = FareRemoteDataSourceImpl(dio);
    when(
      () => dio.post<Map<String, dynamic>>(
        any(),
        data: any<dynamic>(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/api/v1/fares/estimate'),
        statusCode: 200,
        data: const <String, dynamic>{
          'base_fare': 50,
          'distance_charge': 15,
          'time_charge': 4,
          'surge_charge': 0,
          'total_fare': 69,
        },
      ),
    );

    final result = await dataSource.fetchEstimate(
      distanceKm: 3,
      durationMinutes: 12,
      originLatitude: 14.5,
      originLongitude: 121,
      destinationLatitude: 14.6,
      destinationLongitude: 121.1,
    );

    expect(result.totalFare, 69);
    verify(
      () => dio.post<Map<String, dynamic>>(
        '/api/v1/fares/estimate',
        data: <String, dynamic>{
          'distance_km': 3,
          'duration_minutes': 12,
          'origin_latitude': 14.5,
          'origin_longitude': 121,
          'destination_latitude': 14.6,
          'destination_longitude': 121.1,
        },
      ),
    ).called(1);
  });
}
