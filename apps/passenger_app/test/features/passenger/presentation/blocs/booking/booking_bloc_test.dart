import 'package:bloc_test/bloc_test.dart';
import 'package:core_models/core_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/features/booking/data/data_sources/bidding_remote_data_source.dart';
import 'package:passenger_app/src/features/booking/domain/entities/bid_session_trip.dart';
import 'package:passenger_app/src/features/inbox/domain/repositories/i_inbox_repository.dart';
import 'package:passenger_app/src/features/inbox/presentation/bloc/inbox_cubit.dart';
import 'package:passenger_app/src/features/inbox/presentation/bloc/inbox_state.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_driver_repository.dart';
import 'package:passenger_app/src/features/trip/presentation/bloc/booking_bloc.dart';
import 'package:passenger_app/src/features/trip/presentation/bloc/booking_event.dart';
import 'package:passenger_app/src/features/trip/presentation/bloc/booking_state.dart';

class MockDriverRepo extends Mock implements IDriverRepository {}

class MockBiddingRemoteDataSource extends Mock
    implements BiddingRemoteDataSource {}

class MockSecureSessionService extends Mock implements SecureSessionService {}

class MockInboxRepository extends Mock implements IInboxRepository {}

BookingBloc _makeBookingBloc({
  required IDriverRepository driverRepo,
  required BiddingRemoteDataSource biddingDataSource,
  required SecureSessionService secureSessionService,
  InboxCubit? inboxCubit,
}) => BookingBloc(
  driverRepository: driverRepo,
  biddingDataSource: biddingDataSource,
  secureSessionService: secureSessionService,
  inboxCubit: inboxCubit,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDriverRepo driverRepo;
  late MockBiddingRemoteDataSource biddingDataSource;
  late MockSecureSessionService secureSessionService;
  late MockInboxRepository inboxRepository;

  setUp(() {
    driverRepo = MockDriverRepo();
    biddingDataSource = MockBiddingRemoteDataSource();
    secureSessionService = MockSecureSessionService();
    inboxRepository = MockInboxRepository();
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

  const testTrip = BidSessionTrip(
    rideType: 'Solo Ride',
    fare: 100,
    destination: PlaceModel(
      id: 'destination-1',
      name: 'Destination',
      fullAddress: 'Destination address',
      latitude: 7.83,
      longitude: 123.44,
    ),
    distance: '2 km',
    duration: '5 min',
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
        const LocateNearestDriverEvent(
          pickupLat: 7.828,
          pickupLng: 123.434,
          trip: testTrip,
        ),
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
    test(
      'does not report a deliberate cancellation as no driver found',
      () async {
        final inboxCubit = InboxCubit(inboxRepository: inboxRepository);
        final bloc = _makeBookingBloc(
          driverRepo: driverRepo,
          biddingDataSource: biddingDataSource,
          secureSessionService: secureSessionService,
          inboxCubit: inboxCubit,
        );
        when(
          () => biddingDataSource.requestRide(any()),
        ).thenAnswer((_) async => {});

        final searchState = expectLater(
          bloc.stream,
          emits(isA<BookingSearching>()),
        );
        bloc.add(
          const StartOpenBookingEvent(
            trip: testTrip,
            pickupLat: 7.82,
            pickupLng: 123.43,
            distanceKm: 2,
            durationMinutes: 5,
          ),
        );
        await searchState;

        final canceledState = expectLater(
          bloc.stream,
          emits(isA<BookingCanceled>()),
        );
        bloc.add(const CancelBookingEvent());
        await canceledState;

        expect(inboxCubit.state, isA<InboxInitialState>());

        await bloc.close();
        await inboxCubit.close();
      },
    );

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
