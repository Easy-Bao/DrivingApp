import 'package:bloc_test/bloc_test.dart';
import 'package:core_models/core_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/booking/data/data_sources/bidding_remote_data_source.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_driver_repository.dart';
import 'package:passenger_app/src/features/trip/presentation/bloc/booking_bloc.dart';
import 'package:passenger_app/src/features/trip/presentation/bloc/booking_event.dart';
import 'package:passenger_app/src/features/trip/presentation/bloc/booking_state.dart';

import 'package:shared_preferences/shared_preferences.dart';

class MockDriverRepo extends Mock implements IDriverRepository {}

class MockBiddingRemoteDataSource extends Mock
    implements BiddingRemoteDataSource {}

BookingBloc _makeBookingBloc({
  required IDriverRepository driverRepo,
  required BiddingRemoteDataSource biddingDataSource,
}) => BookingBloc(
  driverRepository: driverRepo,
  biddingDataSource: biddingDataSource,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDriverRepo driverRepo;
  late MockBiddingRemoteDataSource biddingDataSource;

  setUp(() {
    driverRepo = MockDriverRepo();
    biddingDataSource = MockBiddingRemoteDataSource();
    SharedPreferences.setMockInitialValues({'passenger_id': 'pass-001'});
  });

  const testDriver = DriverModel(
    id: 'drv-01',
    name: 'Manong Driver',
    vehicleType: 'Sedan',
    plateNumber: 'ABC 1234',
    rating: 4.8,
    lat: 7.828,
    lng: 123.434,
    distanceKm: 0.8,
    etaMinutes: 3,
    score: 95,
  );

  group('BookingBloc — Initial State', () {
    test('starts as BookingInitial', () async {
      final bloc = _makeBookingBloc(
        driverRepo: driverRepo,
        biddingDataSource: biddingDataSource,
      );
      expect(bloc.state, isA<BookingInitial>());
      await bloc.close();
    });
  });

  group('BookingBloc — StartSearchEvent', () {
    blocTest<BookingBloc, BookingState>(
      'emits [SearchingDriver, NearestDriverFound] when nearby drivers exist',
      build: () {
        when(() => driverRepo.getNearbyDrivers(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
        )).thenAnswer((_) async => const Right([testDriver]));

        when(() => biddingDataSource.fetchDriverStats(any())).thenAnswer(
          (_) async => {'totalTrips': 42},
        );
        when(() => biddingDataSource.fetchDriverReviews(any())).thenAnswer(
          (_) async => [],
        );
        return _makeBookingBloc(
          driverRepo: driverRepo,
          biddingDataSource: biddingDataSource,
        );
      },
      act: (bloc) => bloc.add(const StartSearchEvent(
        pickupLat: 7.828,
        pickupLng: 123.434,
        pickupName: 'SM Pagadian',
        dropoffLat: 7.835,
        dropoffLng: 123.444,
        dropoffName: 'Tuburan',
        fare: 150.0,
        rideType: 'nearest',
      )),
      expect: () => [
        isA<SearchingDriver>(),
        isA<NearestDriverFound>()
            .having((s) => s.driver.id, 'driver id', 'drv-01')
            .having((s) => s.totalTrips, 'total trips', 42),
      ],
    );

    blocTest<BookingBloc, BookingState>(
      'emits [SearchingDriver, SearchFailed] when no drivers nearby',
      build: () {
        when(() => driverRepo.getNearbyDrivers(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
        )).thenAnswer((_) async => const Right([]));

        return _makeBookingBloc(
          driverRepo: driverRepo,
          biddingDataSource: biddingDataSource,
        );
      },
      act: (bloc) => bloc.add(const StartSearchEvent(
        pickupLat: 7.828,
        pickupLng: 123.434,
        pickupName: 'SM Pagadian',
        dropoffLat: 7.835,
        dropoffLng: 123.444,
        dropoffName: 'Tuburan',
        fare: 150.0,
        rideType: 'nearest',
      )),
      expect: () => [
        isA<SearchingDriver>(),
        isA<SearchFailed>().having(
          (s) => s.message,
          'error message',
          contains('No drivers'),
        ),
      ],
    );
  });

  group('BookingBloc — CancelSearchEvent', () {
    blocTest<BookingBloc, BookingState>(
      'emits BookingInitial upon cancellation',
      build: () {
        return _makeBookingBloc(
          driverRepo: driverRepo,
          biddingDataSource: biddingDataSource,
        );
      },
      act: (bloc) => bloc.add(const CancelSearchEvent()),
      expect: () => [isA<BookingInitial>()],
    );
  });
}
