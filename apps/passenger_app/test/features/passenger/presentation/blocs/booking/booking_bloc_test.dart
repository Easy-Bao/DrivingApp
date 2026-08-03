import 'package:bloc_test/bloc_test.dart';
import 'package:core_models/core_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/features/booking/data/data_sources/bidding_remote_data_source.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_driver_repository.dart';
import 'package:passenger_app/src/features/trip/presentation/bloc/booking_bloc.dart';
import 'package:passenger_app/src/features/trip/presentation/bloc/booking_event.dart';
import 'package:passenger_app/src/features/trip/presentation/bloc/booking_state.dart';

class MockDriverRepo extends Mock implements IDriverRepository {}

class MockBiddingRemoteDataSource extends Mock
    implements BiddingRemoteDataSource {}

class MockSecureSessionService extends Mock implements SecureSessionService {}

BookingBloc _makeBookingBloc({
  required IDriverRepository driverRepo,
  required BiddingRemoteDataSource biddingDataSource,
  required SecureSessionService secureSessionService,
}) => BookingBloc(
  driverRepository: driverRepo,
  biddingDataSource: biddingDataSource,
  secureSessionService: secureSessionService,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDriverRepo driverRepo;
  late MockBiddingRemoteDataSource biddingDataSource;
  late MockSecureSessionService secureSessionService;

  setUp(() {
    driverRepo = MockDriverRepo();
    biddingDataSource = MockBiddingRemoteDataSource();
    secureSessionService = MockSecureSessionService();
    when(
      () => secureSessionService.readPassengerId(),
    ).thenAnswer((_) async => 'pass-001');
    when(
      () => biddingDataSource.cancelSession(any()),
    ).thenAnswer((_) async => true);
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
        secureSessionService: secureSessionService,
      );
      expect(bloc.state, isA<BookingInitial>());
      await bloc.close();
    });
  });

  group('BookingBloc — LocateNearestDriverEvent', () {
    blocTest<BookingBloc, BookingState>(
      'emits [FindingNearestDriver, NearestDriverFound] when nearby drivers exist',
      build: () {
        when(
          () => driverRepo.getNearbyDrivers(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => const Right([testDriver]));

        when(
          () => biddingDataSource.fetchDriverStats(any()),
        ).thenAnswer((_) async => {'totalTrips': 42});
        when(
          () => biddingDataSource.fetchDriverReviews(any()),
        ).thenAnswer((_) async => []);
        return _makeBookingBloc(
          driverRepo: driverRepo,
          biddingDataSource: biddingDataSource,
          secureSessionService: secureSessionService,
        );
      },
      act: (bloc) => bloc.add(
        const LocateNearestDriverEvent(pickupLat: 7.828, pickupLng: 123.434),
      ),
      expect: () => [
        isA<FindingNearestDriver>(),
        isA<NearestDriverFound>()
            .having((s) => s.driver.id, 'driver id', 'drv-01')
            .having((s) => s.isLoadingReviews, 'isLoadingReviews', true),
        isA<NearestDriverFound>()
            .having((s) => s.driver.id, 'driver id', 'drv-01')
            .having((s) => s.isLoadingReviews, 'isLoadingReviews', false),
      ],
    );
  });

  group('BookingBloc — CancelBookingEvent', () {
    blocTest<BookingBloc, BookingState>(
      'emits BookingCanceled upon cancellation',
      build: () {
        return _makeBookingBloc(
          driverRepo: driverRepo,
          biddingDataSource: biddingDataSource,
          secureSessionService: secureSessionService,
        );
      },
      act: (bloc) => bloc.add(const CancelBookingEvent()),
      expect: () => [isA<BookingCanceled>()],
    );

    blocTest<BookingBloc, BookingState>(
      'emits BookingCanceled when the remote cancellation fails',
      build: () {
        when(
          () => biddingDataSource.cancelSession(any()),
        ).thenThrow(Exception('gateway unavailable'));
        return _makeBookingBloc(
          driverRepo: driverRepo,
          biddingDataSource: biddingDataSource,
          secureSessionService: secureSessionService,
        );
      },
      act: (bloc) => bloc.add(const CancelBookingEvent()),
      expect: () => [isA<BookingCanceled>()],
    );
  });
}
