import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/home/data/datasources/home_remote_data_source.dart';
import 'package:passenger_app/src/features/home/data/repositories/home_repository.dart';
import 'package:passenger_app/src/features/home/domain/entities/home_data.dart';
import 'package:passenger_app/src/features/home/domain/entities/recent_location.dart';

class MockHomeRemoteDataSource extends Mock implements HomeRemoteDataSource {}

void main() {
  test(
    'maps the aggregate home response for guest and signed-in states',
    () async {
      final remoteDataSource = MockHomeRemoteDataSource();
      when(
        () => remoteDataSource.fetchHomeData(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
        ),
      ).thenAnswer(
        (_) async => {
          'current_address': 'Pagadian City',
          'recent_locations': [
            {
              'title': 'City Plaza',
              'subtitle': 'Downtown',
              'lat': 7.8282,
              'lng': 123.4361,
            },
          ],
        },
      );

      final repository = HomeRepository(homeRemoteDataSource: remoteDataSource);

      final result = await repository.loadHomeData(lat: 7.8, lng: 123.4);

      expect(result.isRight(), isTrue);
      expect(
        result.getOrElse(
          (_) => HomeData(currentAddress: '', recentLocations: const []),
        ),
        HomeData(
          currentAddress: 'Pagadian City',
          recentLocations: const [
            RecentLocation(
              title: 'City Plaza',
              subtitle: 'Downtown',
              latitude: 7.8282,
              longitude: 123.4361,
            ),
          ],
        ),
      );
      verify(
        () => remoteDataSource.fetchHomeData(lat: 7.8, lng: 123.4),
      ).called(1);
    },
  );
}
