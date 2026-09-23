import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/auth/domain/failures/auth_failures.dart';
import 'package:passenger/src/features/home/data/data_sources/home_remote_data_source.dart';
import 'package:passenger/src/features/home/data/repositories/home_repository_impl.dart';
import 'package:passenger/src/features/home/domain/entities/home_data.dart';
import 'package:passenger/src/features/home/domain/entities/recent_location.dart';

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

      final repository = HomeRepositoryImpl(
        homeRemoteDataSource: remoteDataSource,
      );

      final result = await repository.loadHomeData(lat: 7.8, lng: 123.4);

      expect(result.isOk, isTrue);
      expect(
        result.getOrElse(
          (_) => const HomeData(currentAddress: '', recentLocations: []),
        ),
        const HomeData(
          currentAddress: 'Pagadian City',
          recentLocations: [
            RecentLocation(
              title: 'City Plaza',
              subtitle: 'Downtown',
              latitude: 7.8282,
              longitude: 123.4361,
            ),
          ],
        ),
      );
      verify(() => remoteDataSource.fetchHomeData(lat: 7.8, lng: 123.4))
          .called(1);
    },
  );

  test('keeps forbidden home responses separate from session expiry', () async {
    final remoteDataSource = MockHomeRemoteDataSource();
    final request = RequestOptions(path: '/api/v1/home');
    when(
      () => remoteDataSource.fetchHomeData(
        lat: any(named: 'lat'),
        lng: any(named: 'lng'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: request,
        response: Response<Object?>(requestOptions: request, statusCode: 403),
        type: DioExceptionType.badResponse,
      ),
    );

    final repository = HomeRepositoryImpl(
      homeRemoteDataSource: remoteDataSource,
    );
    final result = await repository.loadHomeData(lat: 7.8, lng: 123.4);

    result.fold((failure) {
      expect(failure, isA<ServerFailure>());
      expect(failure, isNot(isA<AuthFailure>()));
      expect(failure.message, 'You do not have permission to view home data.');
      expect((failure as ServerFailure).statusCode, 403);
    }, (_) => fail('Expected a permission failure.'));
  });

  test('deduplicates recent locations by normalized title', () async {
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
            'subtitle': 'First visit',
            'lat': 7.8282,
            'lng': 123.4361,
          },
          {
            'title': 'city plaza',
            'subtitle': 'Second visit',
            'lat': 7.8283,
            'lng': 123.4362,
          },
          {
            'title': 'Central Mall',
            'subtitle': 'Third visit',
            'lat': 7.8290,
            'lng': 123.4370,
          },
        ],
      },
    );

    final repository = HomeRepositoryImpl(
      homeRemoteDataSource: remoteDataSource,
    );
    final result = await repository.loadHomeData(lat: 7.8, lng: 123.4);

    expect(result.isOk, isTrue);
    final homeData = result.getOrElse(
      (_) => const HomeData(currentAddress: '', recentLocations: []),
    );
    expect(homeData.recentLocations.length, 2);
    expect(homeData.recentLocations[0].title, 'City Plaza');
    expect(homeData.recentLocations[1].title, 'Central Mall');
  });
}
