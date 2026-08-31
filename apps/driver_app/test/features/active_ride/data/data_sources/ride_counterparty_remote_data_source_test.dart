import 'package:dio/dio.dart';
import 'package:driver_app/src/features/active_ride/data/data_sources/ride_counterparty_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  test('loads the passenger through the authenticated ride contract', () async {
    final dio = MockDio();
    final dataSource = RideCounterpartyRemoteDataSourceImpl(dio);
    when(() => dio.get<Map<String, dynamic>>(any())).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/api/v1/rides/303/counterparty'),
        statusCode: 200,
        data: const {
          'ride_id': 303,
          'user_id': 99,
          'role': 'passenger',
          'name': 'Passenger',
          'phone': '+639000000000',
          'contact_allowed': true,
        },
      ),
    );

    final counterparty = await dataSource.fetch('303');

    verify(
      () => dio.get<Map<String, dynamic>>('/api/v1/rides/303/counterparty'),
    ).called(1);
    expect(counterparty['role'], 'passenger');
    expect(counterparty['contact_allowed'], isTrue);
  });
}
