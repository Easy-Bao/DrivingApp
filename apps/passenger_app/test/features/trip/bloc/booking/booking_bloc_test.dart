import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/features/driver_profile/domain/entities/driver_profile_stats.dart';
import 'package:passenger_app/src/features/driver_profile/domain/repositories/i_driver_profile_repository.dart';
import 'package:passenger_app/src/features/inbox/bloc/inbox/inbox_cubit.dart';
import 'package:passenger_app/src/features/inbox/bloc/inbox/inbox_state.dart';
import 'package:passenger_app/src/features/inbox/domain/repositories/i_inbox_repository.dart';
import 'package:passenger_app/src/features/trip/bloc/booking/booking_bloc.dart';
import 'package:passenger_app/src/features/trip/domain/entities/accepted_booking.dart';
import 'package:passenger_app/src/features/trip/domain/entities/bid_session_trip.dart';
import 'package:passenger_app/src/features/trip/domain/entities/booking_offer.dart';
import 'package:passenger_app/src/features/trip/domain/entities/booking_session_request.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_booking_repository.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_driver_repository.dart';
import 'package:shared_core/shared_core.dart';

class MockDriverRepo extends Mock implements IDriverRepository {}

class MockBookingRepository extends Mock implements IBookingRepository {}

class MockDriverProfileRepository extends Mock
    implements IDriverProfileRepository {}

class FakeBookingSessionRequest extends Fake implements BookingSessionRequest {}

class MockSecureSessionService extends Mock implements SecureSessionService {}

class MockInboxRepository extends Mock implements IInboxRepository {}

BookingBloc _makeBookingBloc({
  required IDriverRepository driverRepo,
  required IBookingRepository bookingRepository,
  required IDriverProfileRepository driverProfileRepository,
  required SecureSessionService secureSessionService,
  InboxCubit? inboxCubit,
  int nearestDriverMaxAttempts = 5,
  Duration nearestDriverRetryDelay = const Duration(seconds: 2),
  Duration offerRefreshInterval = const Duration(seconds: 3),
}) => BookingBloc(
  driverRepository: driverRepo,
  bookingRepository: bookingRepository,
  driverProfileRepository: driverProfileRepository,
  secureSessionService: secureSessionService,
  inboxCubit: inboxCubit,
  nearestDriverMaxAttempts: nearestDriverMaxAttempts,
  nearestDriverRetryDelay: nearestDriverRetryDelay,
  offerRefreshInterval: offerRefreshInterval,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => registerFallbackValue(FakeBookingSessionRequest()));

  late MockDriverRepo driverRepo;
  late MockBookingRepository bookingRepository;
  late MockDriverProfileRepository driverProfileRepository;
  late MockSecureSessionService secureSessionService;
  late MockInboxRepository inboxRepository;

  setUp(() {
    driverRepo = MockDriverRepo();
    bookingRepository = MockBookingRepository();
    driverProfileRepository = MockDriverProfileRepository();
    secureSessionService = MockSecureSessionService();
    inboxRepository = MockInboxRepository();
    when(
      () => secureSessionService.readPassengerId(),
    ).thenAnswer((_) async => 'pass-001');
    when(
      () => bookingRepository.cancelSession(any()),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => bookingRepository.fetchOffers(any()),
    ).thenAnswer((_) async => const Right([]));
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
        bookingRepository: bookingRepository,
        driverProfileRepository: driverProfileRepository,
        secureSessionService: secureSessionService,
      );
      expect(bloc.state, isA<BookingInitial>());
      await bloc.close();
    });

    blocTest<BookingBloc, BookingState>(
      'clears a completed booking session so the next trip can start',
      build: () => _makeBookingBloc(
        driverRepo: driverRepo,
        bookingRepository: bookingRepository,
        driverProfileRepository: driverProfileRepository,
        secureSessionService: secureSessionService,
      ),
      act: (bloc) {
        bloc
          ..add(
            const DriverMatchedEvent(
              DriverMatchResult(
                driverId: 'drv-01',
                driverName: 'Manong Driver',
                vehicleType: 'Sedan',
                plateNumber: 'ABC 1234',
                proposedFare: 100,
              ),
            ),
          )
          ..add(const ResetBookingEvent());
      },
      expect: () => [isA<BookingDriverMatched>(), isA<BookingInitial>()],
      verify: (bloc) => expect(bloc.hasActiveBooking, isFalse),
    );
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

        when(() => driverProfileRepository.fetchStats(any())).thenAnswer(
          (_) async => const Right(DriverProfileStats(completedTrips: 42)),
        );
        when(
          () => driverProfileRepository.fetchReviews(any()),
        ).thenAnswer((_) async => const Right([]));
        return _makeBookingBloc(
          driverRepo: driverRepo,
          bookingRepository: bookingRepository,
          driverProfileRepository: driverProfileRepository,
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

    blocTest<BookingBloc, BookingState>(
      'reports an availability outage instead of claiming no driver exists',
      build: () {
        when(
          () => driverRepo.getNearbyDrivers(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer(
          (_) async =>
              const Left(NetworkFailure('Unable to check nearby drivers.')),
        );
        return _makeBookingBloc(
          driverRepo: driverRepo,
          bookingRepository: bookingRepository,
          driverProfileRepository: driverProfileRepository,
          secureSessionService: secureSessionService,
          nearestDriverMaxAttempts: 5,
          nearestDriverRetryDelay: Duration.zero,
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
        isA<BookingFailure>()
            .having(
              (state) => state.message,
              'message',
              'Check your connection and try again.',
            )
            .having(
              (state) => state.isNoDriverFound,
              'no-driver classification',
              isFalse,
            ),
      ],
      verify: (_) {
        verify(
          () => driverRepo.getNearbyDrivers(lat: 7.828, lng: 123.434),
        ).called(1);
      },
    );

    blocTest<BookingBloc, BookingState>(
      'drops duplicate locate events while a search is active',
      build: () {
        when(
          () => driverRepo.getNearbyDrivers(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => const Right([testDriver]));
        when(() => driverProfileRepository.fetchStats(any())).thenAnswer(
          (_) async => const Right(DriverProfileStats(completedTrips: 42)),
        );
        when(
          () => driverProfileRepository.fetchReviews(any()),
        ).thenAnswer((_) async => const Right([]));
        return _makeBookingBloc(
          driverRepo: driverRepo,
          bookingRepository: bookingRepository,
          driverProfileRepository: driverProfileRepository,
          secureSessionService: secureSessionService,
          nearestDriverMaxAttempts: 1,
          nearestDriverRetryDelay: Duration.zero,
        );
      },
      act: (bloc) {
        const event = LocateNearestDriverEvent(
          pickupLat: 7.828,
          pickupLng: 123.434,
          trip: testTrip,
        );
        bloc
          ..add(event)
          ..add(event);
      },
      expect: () => [
        isA<FindingNearestDriver>(),
        isA<NearestDriverFound>(),
        isA<NearestDriverFound>(),
      ],
      verify: (_) {
        verify(
          () => driverRepo.getNearbyDrivers(lat: 7.828, lng: 123.434),
        ).called(1);
      },
    );
  });

  group('BookingBloc — booking request contract', () {
    const numericDriver = DriverModel(
      id: '42',
      name: 'Numeric Driver',
      vehicleType: 'Sedan',
      plateNumber: 'ABC 1234',
      rating: 4.8,
      lat: 7.828,
      lng: 123.434,
      distanceKm: 0.0,
      etaMinutes: 1,
      score: 0,
    );
    const selectedDriver = DriverModel(
      id: '77',
      name: 'Selected Driver',
      vehicleType: 'Sedan',
      plateNumber: 'XYZ 5678',
      rating: 4.9,
      lat: 7.829,
      lng: 123.435,
      distanceKm: 1.0,
      etaMinutes: 3,
      score: 1,
    );
    const pickupTrip = BidSessionTrip(
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
      pickupAddress: 'Pickup address',
    );

    blocTest<BookingBloc, BookingState>(
      'books the selected driver rather than the nearest driver',
      build: () {
        when(
          () => driverRepo.getNearbyDrivers(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => const Right([numericDriver, selectedDriver]));
        when(() => driverProfileRepository.fetchStats(any())).thenAnswer(
          (_) async => const Right(DriverProfileStats(completedTrips: 1)),
        );
        when(
          () => driverProfileRepository.fetchReviews(any()),
        ).thenAnswer((_) async => const Right([]));
        when(
          () => bookingRepository.createSession(any()),
        ).thenAnswer((_) async => const Right('101'));
        return _makeBookingBloc(
          driverRepo: driverRepo,
          bookingRepository: bookingRepository,
          driverProfileRepository: driverProfileRepository,
          secureSessionService: secureSessionService,
        );
      },
      act: (bloc) async {
        bloc.add(
          const LocateNearestDriverEvent(
            pickupLat: 7.828,
            pickupLng: 123.434,
            trip: pickupTrip,
          ),
        );
        await bloc.stream
            .where((state) => state is NearestDriverFound)
            .take(2)
            .toList();
        bloc.add(
          const StartDirectBookingEvent(
            targetDriver: selectedDriver,
            trip: pickupTrip,
            pickupLat: 7.828,
            pickupLng: 123.434,
            distanceKm: 2,
            durationMinutes: 5,
          ),
        );
      },
      expect: () => [
        isA<FindingNearestDriver>(),
        isA<NearestDriverFound>(),
        isA<NearestDriverFound>(),
        isA<BookingSearching>().having(
          (state) => state.isDirect,
          'direct booking',
          isTrue,
        ),
        isA<BookingOffersReceived>()
            .having((state) => state.isDirect, 'direct booking', isTrue)
            .having((state) => state.offers, 'offers', isEmpty),
      ],
      verify: (_) {
        final request =
            verify(
                  () => bookingRepository.createSession(captureAny()),
                ).captured.single
                as BookingSessionRequest;
        expect(request.targetDriverId, 77);
      },
    );

    blocTest<BookingBloc, BookingState>(
      'accepts a numeric session ID returned by the server',
      build: () {
        when(
          () => bookingRepository.createSession(any()),
        ).thenAnswer((_) async => const Right('202'));
        return _makeBookingBloc(
          driverRepo: driverRepo,
          bookingRepository: bookingRepository,
          driverProfileRepository: driverProfileRepository,
          secureSessionService: secureSessionService,
        );
      },
      act: (bloc) => bloc.add(
        const StartOpenBookingEvent(
          trip: pickupTrip,
          pickupLat: 7.828,
          pickupLng: 123.434,
          distanceKm: 2,
          durationMinutes: 5,
        ),
      ),
      expect: () => [
        isA<BookingSearching>().having(
          (state) => state.isDirect,
          'open booking',
          isFalse,
        ),
        isA<BookingOffersReceived>()
            .having((state) => state.isDirect, 'open booking', isFalse)
            .having((state) => state.offers, 'offers', isEmpty),
      ],
    );

    test(
      'matches a direct booking from snapshot polling when realtime is absent',
      () async {
        var fetchCount = 0;
        when(
          () => bookingRepository.createSession(any()),
        ).thenAnswer((_) async => const Right('26'));
        when(() => bookingRepository.fetchOffers('26')).thenAnswer((_) async {
          fetchCount++;
          if (fetchCount == 1) return const Right([]);
          return const Right([
            BookingOffer(
              offerId: '25',
              sessionId: '26',
              driverId: '2',
              driverName: '',
              vehicleType: '',
              plateNumber: '',
              status: 'pending',
              proposedFareCentavos: 2970,
            ),
          ]);
        });
        when(
          () => bookingRepository.acceptOffer(sessionId: '26', offerId: '25'),
        ).thenAnswer(
          (_) async =>
              const Right(AcceptedBooking(rideId: '24', fareCentavos: 2970)),
        );
        when(
          () => secureSessionService.saveActiveRideId('24'),
        ).thenAnswer((_) async {});

        final bloc = _makeBookingBloc(
          driverRepo: driverRepo,
          bookingRepository: bookingRepository,
          driverProfileRepository: driverProfileRepository,
          secureSessionService: secureSessionService,
          offerRefreshInterval: const Duration(milliseconds: 5),
        );
        final matched = bloc.stream.firstWhere(
          (state) => state is BookingDriverMatched,
        );

        bloc.add(
          const StartDirectBookingEvent(
            targetDriver: DriverModel(
              id: '2',
              name: 'Target Driver',
              vehicleType: 'Sedan',
              plateNumber: 'ABC 1234',
              rating: 4.8,
              lat: 7.828,
              lng: 123.434,
              distanceKm: 0.8,
              etaMinutes: 3,
              score: 95,
            ),
            trip: pickupTrip,
            pickupLat: 7.828,
            pickupLng: 123.434,
            distanceKm: 2,
            durationMinutes: 5,
          ),
        );

        final state =
            await matched.timeout(const Duration(milliseconds: 500))
                as BookingDriverMatched;
        expect(state.matchResult.driverName, 'Target Driver');
        expect(state.matchResult.vehicleType, 'Sedan');
        expect(state.matchResult.plateNumber, 'ABC 1234');
        expect(state.createdRide?.id, '24');
        expect(fetchCount, greaterThanOrEqualTo(2));
        final fetchCountAtMatch = fetchCount;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(fetchCount, fetchCountAtMatch);
        verify(
          () => bookingRepository.acceptOffer(sessionId: '26', offerId: '25'),
        ).called(1);

        await bloc.close();
      },
    );
  });

  group('BookingBloc — CancelBookingEvent', () {
    test(
      'does not report a deliberate cancellation as no driver found',
      () async {
        final inboxCubit = InboxCubit(inboxRepository: inboxRepository);
        final bloc = _makeBookingBloc(
          driverRepo: driverRepo,
          bookingRepository: bookingRepository,
          driverProfileRepository: driverProfileRepository,
          secureSessionService: secureSessionService,
          inboxCubit: inboxCubit,
        );
        when(() => bookingRepository.createSession(any())).thenAnswer(
          (_) async =>
              const Left(ValidationFailure('Booking session was not created.')),
        );

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
          bookingRepository: bookingRepository,
          driverProfileRepository: driverProfileRepository,
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
          () => bookingRepository.cancelSession(any()),
        ).thenThrow(Exception('gateway unavailable'));
        return _makeBookingBloc(
          driverRepo: driverRepo,
          bookingRepository: bookingRepository,
          driverProfileRepository: driverProfileRepository,
          secureSessionService: secureSessionService,
        );
      },
      act: (bloc) => bloc.add(const CancelBookingEvent()),
      expect: () => [isA<BookingCanceled>()],
    );
  });
}
