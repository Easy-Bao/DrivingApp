import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/booking/data/data_sources/booking_remote_data_source.dart';
import 'package:passenger/src/features/booking/data/repositories/booking_repository_impl.dart';
import 'package:passenger/src/features/booking/domain/entities/booking_session_request.dart';

class MockBookingRemoteDataSource extends Mock
    implements BookingRemoteDataSource {}

void main() {
  late MockBookingRemoteDataSource dataSource;
  late BookingRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  setUp(() {
    dataSource = MockBookingRemoteDataSource();
    repository = BookingRepositoryImpl(dataSource: dataSource);
  });

  test('serializes IDs and money using the server booking contract', () async {
    Map<String, dynamic>? sentBody;
    when(() => dataSource.createSession(any())).thenAnswer((invocation) async {
      sentBody = Map<String, dynamic>.from(
        invocation.positionalArguments.single as Map,
      );
      return <String, dynamic>{'id': 77};
    });

    final result = await repository.createSession(
      const BookingSessionRequest(
        rideType: 'solo',
        pickupLatitude: 7.828,
        pickupLongitude: 123.434,
        pickupName: 'Mountain View',
        dropoffLatitude: 7.85,
        dropoffLongitude: 123.45,
        dropoffName: 'Vista Slope',
        distanceKm: 3.2,
        durationMinutes: 8,
        customFareCentavos: 2764,
        passengerNote: 'Gate 2',
        targetDriverId: 42,
      ),
    );

    expect(result, const Right<Failure, String>('77'));
    expect(sentBody?['target_driver_id'], 42);
    expect(sentBody?['custom_fare_centavos'], 2764);
    expect(sentBody?['dropoff_latitude'], 7.85);
    expect(sentBody?['dropoff_longitude'], 123.45);
    expect(sentBody, isNot(contains('custom_fare')));
  });

  test('normalizes numeric accepted ride IDs and centavo fare', () async {
    when(
      () => dataSource.acceptOffer(sessionId: 'session-1', offerId: 'offer-2'),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'ride_id': 901,
        'ride': <String, dynamic>{'fare_centavos': '2764'},
      },
    );

    final result = await repository.acceptOffer(
      sessionId: 'session-1',
      offerId: 'offer-2',
    );

    expect(result.isRight(), isTrue);
    final booking = result.getOrElse(
      (_) => throw StateError('Expected an accepted booking.'),
    );
    expect(booking.rideId, '901');
    expect(booking.fareCentavos, 2764);
  });

  test(
    'keeps an actionable offer when optional driver display fields are blank',
    () async {
      when(() => dataSource.fetchOffers('26')).thenAnswer(
        (_) async => <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 25,
            'session_id': 26,
            'driver_id': 2,
            'driver_name': '',
            'vehicle_type': '',
            'plate_number': '',
            'proposed_fare_centavos': 2970,
            'status': 'pending',
          },
        ],
      );

      final result = await repository.fetchOffers('26');

      expect(result.isRight(), isTrue);
      final offers = result.getOrElse(
        (_) => throw StateError('Expected the pending offer to be retained.'),
      );
      expect(offers, hasLength(1));
      expect(offers.single.offerId, '25');
      expect(offers.single.sessionId, '26');
      expect(offers.single.driverId, '2');
      expect(offers.single.proposedFareCentavos, 2970);
    },
  );
}
