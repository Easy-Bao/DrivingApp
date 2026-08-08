import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/features/home/data/repositories/home_repository.dart';
import 'package:passenger_app/src/features/trip/data/datasources/passenger_remote_data_source.dart';
import 'package:shared_core/shared_core.dart';

class MockPassengerRemoteDataSource extends Mock
    implements PassengerRemoteDataSource {}

class MockSecureSessionService extends Mock implements SecureSessionService {}

void main() {
  test('uses the city context instead of a postcode for the pickup label', () {
    const place = PlaceModel(
      id: 'postcode.7016',
      name: '7016',
      fullAddress: '7016, Philippines',
      latitude: 7.8282,
      longitude: 123.4361,
      context: {'place': 'Pagadian City'},
    );

    expect(formatHomeAddress(place), 'Pagadian City');
  });

  test('uses city context when the provider omits a full address', () {
    const place = PlaceModel(
      id: 'postcode.7016',
      name: '7016',
      fullAddress: '',
      latitude: 7.8282,
      longitude: 123.4361,
      context: {'place': 'Pagadian City'},
    );

    expect(formatHomeAddress(place), 'Pagadian City');
  });

  test('guest home skips authenticated ride-history requests', () async {
    final remoteDataSource = MockPassengerRemoteDataSource();
    final secureSessionService = MockSecureSessionService();
    when(
      () => secureSessionService.readPassengerId(),
    ).thenAnswer((_) async => null);

    final repository = HomeRepository(
      passengerRemoteDataSource: remoteDataSource,
      secureSessionService: secureSessionService,
    );

    final result = await repository.getRecentLocations();

    expect(result.isRight(), isTrue);
    expect(result.getOrElse((_) => const []), isEmpty);
    verifyNever(() => remoteDataSource.fetchRideHistory(any()));
  });
}
