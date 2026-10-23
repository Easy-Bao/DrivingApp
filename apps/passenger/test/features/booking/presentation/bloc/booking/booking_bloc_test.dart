import 'dart:async';
import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:maps/maps.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/booking/booking.dart';
import 'package:passenger/src/features/booking/domain/entities/bid_session_trip.dart';
import 'package:passenger/src/features/booking/domain/entities/booking_offer.dart';
import 'package:passenger/src/features/booking/domain/entities/booking_session_request.dart';
import 'package:passenger/src/features/booking/domain/repositories/booking_repository.dart';
import 'package:passenger/src/features/booking/domain/repositories/driver_repository.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_profile_stats.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_review.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';

class MockDriverRepo extends Mock implements DriverRepository {}

class MockBookingRepository extends Mock implements BookingRepository {}

class MockDriverProfileRepository extends Mock
    implements DriverProfileRepository {}

class FakeBookingSessionRequest extends Fake implements BookingSessionRequest {}

class MockSecureSessionService extends Mock implements SessionStore {}

BookingBloc _makeBookingBloc({
  required DriverRepository driverRepo,
  required BookingRepository bookingRepository,
  required DriverProfileRepository driverProfileRepository,
  required SessionStore secureSessionService,
  AppLifecycleCoordinator? lifecycleCoordinator,
  int nearestDriverMaxAttempts = 5,
  Duration nearestDriverRetryDelay = const Duration(seconds: 2),
  Duration offerRefreshInterval = const Duration(seconds: 3),
}) => BookingBloc(
  driverRepository: driverRepo,
  bookingRepository: bookingRepository,
  driverProfileRepository: driverProfileRepository,
  secureSessionService: secureSessionService,
  lifecycleCoordinator: lifecycleCoordinator ?? AppLifecycleCoordinator(),
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
  PendingBidSessionCreation? pendingCreation;
  String? pendingCancellationId;

  setUp(() {
    driverRepo = MockDriverRepo();
    bookingRepository = MockBookingRepository();
    driverProfileRepository = MockDriverProfileRepository();
    secureSessionService = MockSecureSessionService();
    pendingCreation = null;
    pendingCancellationId = null;
    when(() => secureSessionService.readPassengerId())
        .thenAnswer((_) async => 'pass-001');
    when(() => secureSessionService.readActiveRideId())
        .thenAnswer((_) async => null);
    when(() => secureSessionService.readActiveBidSessionId())
        .thenAnswer((_) async => null);
    when(() => secureSessionService.readPendingBidSessionCreation())
        .thenAnswer((_) async => pendingCreation);
    when(() => secureSessionService.readPendingBidSessionCancellationId())
        .thenAnswer((_) async => pendingCancellationId);
    when(
      () => secureSessionService.savePendingBidSessionCreation(
        idempotencyKey: any(named: 'idempotencyKey'),
        requestPayload: any(named: 'requestPayload'),
        cancelRequested: any(named: 'cancelRequested'),
        sessionId: any(named: 'sessionId'),
      ),
    ).thenAnswer((invocation) async {
      pendingCreation = (
        idempotencyKey: invocation.namedArguments[#idempotencyKey] as String,
        requestPayload: invocation.namedArguments[#requestPayload] as String,
        cancelRequested: invocation.namedArguments[#cancelRequested] as bool,
        sessionId: invocation.namedArguments[#sessionId] as String?,
      );
    });
    when(() => secureSessionService.requestPendingBidSessionCancellation())
        .thenAnswer((_) async {
          final current = pendingCreation;
          if (current != null) {
            pendingCreation = (
              idempotencyKey: current.idempotencyKey,
              requestPayload: current.requestPayload,
              cancelRequested: true,
              sessionId: current.sessionId,
            );
          }
        });
    when(() => secureSessionService.attachPendingBidSessionId(any()))
        .thenAnswer((invocation) async {
          final current = pendingCreation;
          if (current != null) {
            pendingCreation = (
              idempotencyKey: current.idempotencyKey,
              requestPayload: current.requestPayload,
              cancelRequested: current.cancelRequested,
              sessionId: invocation.positionalArguments.single as String,
            );
          }
        });
    when(() => secureSessionService.deletePendingBidSessionCreation())
        .thenAnswer((_) async {
          pendingCreation = null;
        });
    when(
      () => secureSessionService.savePendingBidSessionCancellationId(any()),
    ).thenAnswer((invocation) async {
      pendingCancellationId = invocation.positionalArguments.single as String;
    });
    when(() => secureSessionService.deletePendingBidSessionCancellationId())
        .thenAnswer((_) async {
          pendingCancellationId = null;
        });
    when(() => secureSessionService.saveActiveBidSessionId(any()))
        .thenAnswer((_) async {});
    when(() => secureSessionService.deleteActiveBidSessionId())
        .thenAnswer((_) async {});
    when(() => secureSessionService.saveActiveRideId(any()))
        .thenAnswer((_) async {});
    when(() => bookingRepository.cancelSession(any()))
        .thenAnswer((_) async => const Ok(null));
    when(() => bookingRepository.fetchOffers(any()))
        .thenAnswer((_) async => const Ok([]));
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
    fare: 100,
    destination: Place(
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

  group('BookingBloc — RestoreActiveBookingEvent', () {
    test(
      'replays the saved create request with its original idempotency key',
      () async {
        const request = BookingSessionRequest(
          pickupLatitude: 7.828,
          pickupLongitude: 123.434,
          pickupName: 'Pickup address',
          dropoffLatitude: 7.83,
          dropoffLongitude: 123.44,
          dropoffName: 'Destination address',
          distanceKm: 2,
          durationMinutes: 5,
          customFareAmount: 10000,
          passengerNote: '',
        );
        pendingCreation = (
          idempotencyKey: 'saved-key-12345678',
          requestPayload: jsonEncode(request.toJson()),
          cancelRequested: false,
          sessionId: null,
        );
        when(() => bookingRepository.createSession(any())).thenAnswer(
          (_) async => const Ok(
            BidSessionSnapshot(
              id: 'restored-session',
              status: 'open',
              expiresAt: null,
              bookingReference: '701612345678901',
            ),
          ),
        );

        final bloc = _makeBookingBloc(
          driverRepo: driverRepo,
          bookingRepository: bookingRepository,
          driverProfileRepository: driverProfileRepository,
          secureSessionService: secureSessionService,
        );
        addTearDown(bloc.close);

        final restored = bloc.stream.firstWhere(
          (state) =>
              state is BookingSearching &&
              state.sessionId == 'restored-session',
        );
        bloc.add(const RestoreActiveBookingEvent());
        await restored.timeout(const Duration(milliseconds: 500));

        final replay =
            verify(() => bookingRepository.createSession(captureAny()))
                    .captured
                    .single
                as BookingSessionRequest;
        expect(replay.idempotencyKey, 'saved-key-12345678');
        expect(replay.toJson(), request.toJson());
        expect(bloc.activeBidSessionId, 'restored-session');
        expect(
          bloc.activeDriverSearch?.trip.destination.name,
          'Destination address',
        );
      },
    );
  });

  group('BookingBloc — LocateNearestDriverEvent', () {
    test(
      'retries empty discovery before showing the request action state',
      () async {
        var lookupCount = 0;
        when(
          () => driverRepo.getNearbyDrivers(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async {
          lookupCount++;
          return const Ok([]);
        });
        final bloc = _makeBookingBloc(
          driverRepo: driverRepo,
          bookingRepository: bookingRepository,
          driverProfileRepository: driverProfileRepository,
          secureSessionService: secureSessionService,
          nearestDriverMaxAttempts: 3,
          nearestDriverRetryDelay: Duration.zero,
        );

        final failure = bloc.stream.firstWhere(
          (state) => state is BookingFailure,
        );
        bloc.add(
          const LocateNearestDriverEvent(
            pickupLat: 7.828,
            pickupLng: 123.434,
            trip: testTrip,
          ),
        );

        final failureState = await failure as BookingFailure;
        expect(failureState.message, 'No drivers nearby');
        expect(failureState.isNoDriverFound, isTrue);
        expect(lookupCount, 3);
        verify(() => driverRepo.getNearbyDrivers(lat: 7.828, lng: 123.434))
            .called(3);

        await bloc.close();
      },
    );

    test('uses the bounded five-lookup production default', () async {
      var lookupCount = 0;
      when(
        () => driverRepo.getNearbyDrivers(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
        ),
      ).thenAnswer((_) async {
        lookupCount++;
        return const Ok([]);
      });
      final bloc = BookingBloc(
        driverRepository: driverRepo,
        bookingRepository: bookingRepository,
        driverProfileRepository: driverProfileRepository,
        secureSessionService: secureSessionService,
        lifecycleCoordinator: AppLifecycleCoordinator(),
        nearestDriverRetryDelay: Duration.zero,
      );
      addTearDown(bloc.close);

      final failure = bloc.stream.firstWhere(
        (state) => state is BookingFailure,
      );
      bloc.add(
        const LocateNearestDriverEvent(
          pickupLat: 7.828,
          pickupLng: 123.434,
          trip: testTrip,
        ),
      );
      await failure.timeout(const Duration(milliseconds: 500));

      expect(lookupCount, 5);
    });

    test(
      'keeps the active trip available when the search leaves the page',
      () async {
        when(
          () => driverRepo.getNearbyDrivers(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => const Ok([testDriver]));
        when(() => driverProfileRepository.fetchStats(any())).thenAnswer(
          (_) async => const Ok(DriverProfileStats(completedTrips: 42)),
        );
        when(() => driverProfileRepository.fetchReviews(any())).thenAnswer(
          (_) async => const Ok(
            OffsetPage<DriverReview>(
              items: [],
              hasMore: false,
              nextOffset: null,
            ),
          ),
        );
        final bloc = _makeBookingBloc(
          driverRepo: driverRepo,
          bookingRepository: bookingRepository,
          driverProfileRepository: driverProfileRepository,
          secureSessionService: secureSessionService,
          nearestDriverMaxAttempts: 1,
          nearestDriverRetryDelay: Duration.zero,
        );

        final finding = bloc.stream.firstWhere(
          (state) => state is FindingNearestDriver,
        );
        final nearest = bloc.stream.firstWhere(
          (state) => state is NearestDriverFound,
        );
        bloc.add(
          const LocateNearestDriverEvent(
            pickupLat: 7.828,
            pickupLng: 123.434,
            trip: testTrip,
          ),
        );
        await finding;

        expect(bloc.activeDriverSearch?.trip, testTrip);
        expect(bloc.activeDriverSearch?.pickupLat, 7.828);
        expect(bloc.activeDriverSearch?.pickupLng, 123.434);

        await nearest;
        await bloc.close();
      },
    );

    blocTest<BookingBloc, BookingState>(
      'emits [FindingNearestDriver, NearestDriverFound] when nearby drivers exist',
      build: () {
        when(
          () => driverRepo.getNearbyDrivers(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => const Ok([testDriver]));

        when(() => driverProfileRepository.fetchStats(any())).thenAnswer(
          (_) async => const Ok(DriverProfileStats(completedTrips: 42)),
        );
        when(() => driverProfileRepository.fetchReviews(any())).thenAnswer(
          (_) async => const Ok(
            OffsetPage<DriverReview>(
              items: [],
              hasMore: false,
              nextOffset: null,
            ),
          ),
        );
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
              const Err(NetworkFailure('Unable to check nearby drivers.')),
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
              "Couldn't connect. Check your internet connection and try again.",
            )
            .having(
              (state) => state.isNoDriverFound,
              'no-driver classification',
              isFalse,
            ),
      ],
      verify: (_) {
        verify(() => driverRepo.getNearbyDrivers(lat: 7.828, lng: 123.434))
            .called(1);
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
        ).thenAnswer((_) async => const Ok([testDriver]));
        when(() => driverProfileRepository.fetchStats(any())).thenAnswer(
          (_) async => const Ok(DriverProfileStats(completedTrips: 42)),
        );
        when(() => driverProfileRepository.fetchReviews(any())).thenAnswer(
          (_) async => const Ok(
            OffsetPage<DriverReview>(
              items: [],
              hasMore: false,
              nextOffset: null,
            ),
          ),
        );
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
        verify(() => driverRepo.getNearbyDrivers(lat: 7.828, lng: 123.434))
            .called(1);
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
      fare: 100,
      destination: Place(
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
        ).thenAnswer((_) async => const Ok([numericDriver, selectedDriver]));
        when(() => driverProfileRepository.fetchStats(any())).thenAnswer(
          (_) async => const Ok(DriverProfileStats(completedTrips: 1)),
        );
        when(() => driverProfileRepository.fetchReviews(any())).thenAnswer(
          (_) async => const Ok(
            OffsetPage<DriverReview>(
              items: [],
              hasMore: false,
              nextOffset: null,
            ),
          ),
        );
        when(() => bookingRepository.createSession(any())).thenAnswer(
          (_) async => const Ok(
            BidSessionSnapshot(
              id: '101',
              status: 'open',
              expiresAt: null,
              bookingReference: '701612345678901',
            ),
          ),
        );
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
        isA<BookingSearching>()
            .having((state) => state.isDirect, 'direct booking', isTrue)
            .having((state) => state.sessionId, 'request ID', isNotNull),
        isA<BookingOffersReceived>()
            .having((state) => state.isDirect, 'direct booking', isTrue)
            .having((state) => state.offers, 'offers', isEmpty),
      ],
      verify: (_) {
        final request =
            verify(() => bookingRepository.createSession(captureAny()))
                    .captured
                    .single
                as BookingSessionRequest;
        expect(request.targetDriverId, 77);
      },
    );

    blocTest<BookingBloc, BookingState>(
      'accepts a numeric session ID returned by the server',
      build: () {
        when(() => bookingRepository.createSession(any())).thenAnswer(
          (_) async => const Ok(
            BidSessionSnapshot(
              id: '202',
              status: 'open',
              expiresAt: null,
              bookingReference: '701612345678901',
            ),
          ),
        );
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
        isA<BookingSearching>()
            .having((state) => state.isDirect, 'open booking', isFalse)
            .having((state) => state.sessionId, 'request ID', '202')
            .having(
              (state) => state.bookingReference,
              'public booking number',
              '701612345678901',
            ),
        isA<BookingOffersReceived>()
            .having((state) => state.isDirect, 'open booking', isFalse)
            .having((state) => state.offers, 'offers', isEmpty),
      ],
    );

    test(
      'persists an open booking before listening for driver offers',
      () async {
        when(() => bookingRepository.createSession(any())).thenAnswer(
          (_) async => const Ok(
            BidSessionSnapshot(
              id: 'cash-booking',
              status: 'open',
              expiresAt: null,
              bookingReference: '701612345678901',
            ),
          ),
        );
        final bloc = _makeBookingBloc(
          driverRepo: driverRepo,
          bookingRepository: bookingRepository,
          driverProfileRepository: driverProfileRepository,
          secureSessionService: secureSessionService,
        );
        addTearDown(bloc.close);
        final created = bloc.stream.firstWhere(
          (state) =>
              state is BookingSearching && state.sessionId == 'cash-booking',
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
        await created.timeout(const Duration(seconds: 1));
        verifyInOrder([
          () => bookingRepository.createSession(any()),
          () => secureSessionService.saveActiveBidSessionId('cash-booking'),
        ]);
        verifyNever(
          () => driverRepo.getNearbyDrivers(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        );
        expect(bloc.activeBidSessionId, 'cash-booking');
      },
    );

    test('cancels the persisted booking ID when dispatch expires', () async {
      when(() => bookingRepository.createSession(any())).thenAnswer(
        (_) async => const Ok(
          BidSessionSnapshot(
            id: 'expired-cash-booking',
            status: 'open',
            expiresAt: null,
            bookingReference: '701612345678901',
          ),
        ),
      );
      final bloc = _makeBookingBloc(
        driverRepo: driverRepo,
        bookingRepository: bookingRepository,
        driverProfileRepository: driverProfileRepository,
        secureSessionService: secureSessionService,
      );
      addTearDown(bloc.close);
      final created = bloc.stream.firstWhere(
        (state) => state is BookingOffersReceived,
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
      await created.timeout(const Duration(seconds: 1));
      final expired = bloc.stream.firstWhere(
        (state) => state is BookingFailure && state.isRequestExpired,
      );
      bloc.add(
        UpdateOffersEvent(
          const [],
          session: BidSessionSnapshot(
            id: 'expired-cash-booking',
            status: 'expired',
            expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
          ),
        ),
      );
      await expired.timeout(const Duration(seconds: 1));
      verify(() => bookingRepository.cancelSession('expired-cash-booking'))
          .called(1);
      expect(bloc.activeBidSessionId, isNull);
      expect(pendingCancellationId, isNull);
    });

    test(
      'matches a direct booking from snapshot polling when realtime is absent',
      () async {
        var fetchCount = 0;
        when(() => bookingRepository.createSession(any())).thenAnswer(
          (_) async => const Ok(
            BidSessionSnapshot(
              id: '26',
              status: 'open',
              expiresAt: null,
              bookingReference: '701612345678901',
            ),
          ),
        );
        when(() => bookingRepository.fetchOffers('26')).thenAnswer((_) async {
          fetchCount++;
          if (fetchCount == 1) return const Ok([]);
          return const Ok([
            BookingOffer(
              offerId: '25',
              sessionId: '26',
              driverId: '2',
              driverName: '',
              vehicleType: '',
              plateNumber: '',
              status: 'pending',
              proposedFareAmount: 2970,
            ),
          ]);
        });
        when(
          () => bookingRepository.acceptOffer(sessionId: '26', offerId: '25'),
        ).thenAnswer(
          (_) async =>
              const Ok(AcceptedBooking(rideId: '24', fareAmount: 2970)),
        );
        when(() => secureSessionService.saveActiveRideId('24'))
            .thenAnswer((_) async {});

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

        final state = await matched.timeout(
          const Duration(milliseconds: 500),
        ) as BookingDriverMatched;
        expect(state.matchResult.driverName, 'Target Driver');
        expect(state.matchResult.vehicleType, 'Sedan');
        expect(state.matchResult.plateNumber, 'ABC 1234');
        expect(state.rideId, '24');
        expect(state.matchResult.proposedFare, 29.7);
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
    test('stops offer polling after the booking session is canceled', () async {
      final lifecycleCoordinator = AppLifecycleCoordinator();
      var fetchCount = 0;
      when(() => bookingRepository.createSession(any())).thenAnswer(
        (_) async => const Ok(
          BidSessionSnapshot(
            id: 'cancel-session',
            status: 'open',
            expiresAt: null,
            bookingReference: '701612345678901',
          ),
        ),
      );
      when(() => bookingRepository.fetchOffers('cancel-session'))
          .thenAnswer((_) async {
            fetchCount++;
            return const Ok([]);
          });
      final bloc = _makeBookingBloc(
        driverRepo: driverRepo,
        bookingRepository: bookingRepository,
        driverProfileRepository: driverProfileRepository,
        secureSessionService: secureSessionService,
        lifecycleCoordinator: lifecycleCoordinator,
        offerRefreshInterval: const Duration(milliseconds: 5),
      );
      var blocClosed = false;
      addTearDown(() async {
        if (!blocClosed) await bloc.close();
        await lifecycleCoordinator.dispose();
      });

      final offersReceived = bloc.stream.firstWhere(
        (state) => state is BookingOffersReceived,
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
      await offersReceived.timeout(const Duration(milliseconds: 500));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(fetchCount, greaterThan(1));

      final bookingCanceled = bloc.stream.firstWhere(
        (state) => state is BookingCanceled,
      );
      bloc.add(const CancelBookingEvent());
      await bookingCanceled.timeout(const Duration(milliseconds: 500));
      final fetchCountAtCancellation = fetchCount;
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(fetchCount, fetchCountAtCancellation);
      await bloc.close();
      blocClosed = true;
    });

    test(
      'retries an ambiguous creation with the same request before canceling',
      () async {
        var createCalls = 0;
        when(() => bookingRepository.createSession(any()))
            .thenAnswer((_) async {
              createCalls++;
              if (createCalls == 1) {
                return const Err(ServerFailure('Booking request timed out.'));
              }
              return const Ok(
                BidSessionSnapshot(
                  id: 'created-after-retry',
                  status: 'open',
                  expiresAt: null,
                  bookingReference: '701612345678901',
                ),
              );
            });
        when(() => bookingRepository.cancelSession('created-after-retry'))
            .thenAnswer((_) async => const Ok(null));
        final bloc = _makeBookingBloc(
          driverRepo: driverRepo,
          bookingRepository: bookingRepository,
          driverProfileRepository: driverProfileRepository,
          secureSessionService: secureSessionService,
        );

        final initialFailure = bloc.stream.firstWhere(
          (state) => state is BookingSessionRecoveryFailure,
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
        await initialFailure;

        final canceledState = bloc.stream.firstWhere(
          (state) => state is BookingCanceled,
        );
        bloc.add(const CancelBookingEvent());
        await canceledState;

        final captured = verify(
          () => bookingRepository.createSession(captureAny()),
        ).captured.cast<BookingSessionRequest>();
        expect(captured, hasLength(2));
        expect(captured[0].idempotencyKey, isNotEmpty);
        expect(captured[1].idempotencyKey, captured[0].idempotencyKey);
        expect(captured[1].toJson(), captured[0].toJson());
        expect(pendingCreation, isNull);
        expect(pendingCancellationId, isNull);

        await bloc.close();
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
      'emits BookingCanceled when no active session exists',
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

    test('emits BookingCanceled and clears active session when remote cancellation succeeds', () async {
      when(() => bookingRepository.createSession(any())).thenAnswer(
        (_) async => const Ok(
          BidSessionSnapshot(
            id: 'cancel-session-1',
            status: 'open',
            expiresAt: null,
            bookingReference: '701612345678901',
          ),
        ),
      );
      when(() => bookingRepository.fetchOffers('cancel-session-1'))
          .thenAnswer((_) async => const Ok([]));
      when(() => bookingRepository.cancelSession('cancel-session-1'))
          .thenAnswer((_) async => const Ok(null));

      final bloc = _makeBookingBloc(
        driverRepo: driverRepo,
        bookingRepository: bookingRepository,
        driverProfileRepository: driverProfileRepository,
        secureSessionService: secureSessionService,
      );
      addTearDown(bloc.close);

      final offersReceived = bloc.stream.firstWhere(
        (state) => state is BookingOffersReceived,
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
      await offersReceived.timeout(const Duration(milliseconds: 500));
      expect(bloc.activeBidSessionId, 'cancel-session-1');

      final bookingCanceled = bloc.stream.firstWhere(
        (state) => state is BookingCanceled,
      );
      bloc.add(const CancelBookingEvent());
      await bookingCanceled.timeout(const Duration(milliseconds: 500));

      expect(bloc.activeBidSessionId, isNull);
      verify(() => secureSessionService.deleteActiveBidSessionId()).called(1);
    });

    test('emits BookingFailure and retains active session when remote cancellation fails', () async {
      when(() => bookingRepository.createSession(any())).thenAnswer(
        (_) async => const Ok(
          BidSessionSnapshot(
            id: 'cancel-session-2',
            status: 'open',
            expiresAt: null,
            bookingReference: '701612345678901',
          ),
        ),
      );
      when(() => bookingRepository.fetchOffers('cancel-session-2'))
          .thenAnswer((_) async => const Ok([]));
      when(() => bookingRepository.cancelSession('cancel-session-2'))
          .thenAnswer((_) async => const Err(ServerFailure('offline')));
      when(() => bookingRepository.fetchSession('cancel-session-2')).thenAnswer(
        (_) async => const Ok(
          BidSessionSnapshot(
            id: 'cancel-session-2',
            status: 'open',
            expiresAt: null,
          ),
        ),
      );

      final bloc = _makeBookingBloc(
        driverRepo: driverRepo,
        bookingRepository: bookingRepository,
        driverProfileRepository: driverProfileRepository,
        secureSessionService: secureSessionService,
      );
      addTearDown(bloc.close);

      final offersReceived = bloc.stream.firstWhere(
        (state) => state is BookingOffersReceived,
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
      await offersReceived.timeout(const Duration(milliseconds: 500));
      expect(bloc.activeBidSessionId, 'cancel-session-2');

      final failureState = bloc.stream.firstWhere(
        (state) => state is BookingSessionRecoveryFailure,
      );
      bloc.add(const CancelBookingEvent());
      final state = await failureState.timeout(
        const Duration(milliseconds: 500),
      );

      expect(state, isA<BookingSessionRecoveryFailure>());
      expect(
        (state as BookingSessionRecoveryFailure).message,
        contains('offline'),
      );
      expect(bloc.activeBidSessionId, 'cancel-session-2');
      verifyNever(() => secureSessionService.deleteActiveBidSessionId());
    });

    test('emits BookingFailure and retains active session when cancellation times out', () async {
      when(() => bookingRepository.createSession(any())).thenAnswer(
        (_) async => const Ok(
          BidSessionSnapshot(
            id: 'cancel-session-3',
            status: 'open',
            expiresAt: null,
            bookingReference: '701612345678901',
          ),
        ),
      );
      when(() => bookingRepository.fetchOffers('cancel-session-3'))
          .thenAnswer((_) async => const Ok([]));
      when(() => bookingRepository.cancelSession('cancel-session-3'))
          .thenThrow(TimeoutException('request timed out'));
      when(() => bookingRepository.fetchSession('cancel-session-3')).thenAnswer(
        (_) async => const Ok(
          BidSessionSnapshot(
            id: 'cancel-session-3',
            status: 'open',
            expiresAt: null,
          ),
        ),
      );

      final bloc = _makeBookingBloc(
        driverRepo: driverRepo,
        bookingRepository: bookingRepository,
        driverProfileRepository: driverProfileRepository,
        secureSessionService: secureSessionService,
      );
      addTearDown(bloc.close);

      final offersReceived = bloc.stream.firstWhere(
        (state) => state is BookingOffersReceived,
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
      await offersReceived.timeout(const Duration(milliseconds: 500));
      expect(bloc.activeBidSessionId, 'cancel-session-3');

      final failureState = bloc.stream.firstWhere(
        (state) => state is BookingSessionRecoveryFailure,
      );
      bloc.add(const CancelBookingEvent());
      final state = await failureState.timeout(
        const Duration(milliseconds: 500),
      );

      expect(state, isA<BookingSessionRecoveryFailure>());
      expect(bloc.activeBidSessionId, 'cancel-session-3');
      verifyNever(() => secureSessionService.deleteActiveBidSessionId());
    });

    test(
      'cancels a session after the pending create request resolves',
      () async {
        final creation = Completer<Result<BidSessionSnapshot, Failure>>();
        when(() => bookingRepository.createSession(any()))
            .thenAnswer((_) => creation.future);
        when(() => bookingRepository.cancelSession('31'))
            .thenAnswer((_) async => const Ok(null));

        final bloc = _makeBookingBloc(
          driverRepo: driverRepo,
          bookingRepository: bookingRepository,
          driverProfileRepository: driverProfileRepository,
          secureSessionService: secureSessionService,
        );
        addTearDown(bloc.close);

        final searching = bloc.stream.firstWhere(
          (state) => state is BookingSearching,
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
        await searching;
        await Future<void>.delayed(const Duration(milliseconds: 20));

        final cancellationRequested = bloc.stream.firstWhere(
          (state) => state is BookingSessionRecoveryInProgress,
        );
        bloc.add(const CancelBookingEvent());
        await cancellationRequested.timeout(const Duration(milliseconds: 500));
        verifyNever(() => bookingRepository.cancelSession('31'));

        final canceled = bloc.stream.firstWhere(
          (state) => state is BookingCanceled,
        );
        creation.complete(
          const Ok(
            BidSessionSnapshot(
              id: '31',
              status: 'open',
              expiresAt: null,
              bookingReference: '701612345678901',
            ),
          ),
        );
        await canceled.timeout(const Duration(milliseconds: 500));

        verify(() => bookingRepository.cancelSession('31')).called(1);
        verifyNever(() => bookingRepository.fetchOffers('31'));
        expect(bloc.activeBidSessionId, isNull);
        expect(bloc.state, isA<BookingCanceled>());
      },
    );

    test(
      'recovers an accepted session when cancellation loses the race',
      () async {
        var sessionReads = 0;
        when(() => bookingRepository.createSession(any())).thenAnswer(
          (_) async => const Ok(
            BidSessionSnapshot(
              id: 'cancel-session-4',
              status: 'open',
              expiresAt: null,
              bookingReference: '701612345678901',
            ),
          ),
        );
        when(() => bookingRepository.fetchOffers('cancel-session-4'))
            .thenAnswer((_) async => const Ok([]));
        when(
          () => bookingRepository.cancelSession('cancel-session-4'),
        ).thenAnswer(
          (_) async =>
              const Err(ValidationFailure('The booking was already accepted.')),
        );
        when(() => bookingRepository.fetchSession('cancel-session-4'))
            .thenAnswer((_) async {
              sessionReads++;
              if (sessionReads == 1) {
                return const Ok(
                  BidSessionSnapshot(
                    id: 'cancel-session-4',
                    status: 'open',
                    expiresAt: null,
                  ),
                );
              }
              return const Ok(
                BidSessionSnapshot(
                  id: 'cancel-session-4',
                  status: 'accepted',
                  expiresAt: null,
                  rideId: 'ride-55',
                ),
              );
            });

        final bloc = _makeBookingBloc(
          driverRepo: driverRepo,
          bookingRepository: bookingRepository,
          driverProfileRepository: driverProfileRepository,
          secureSessionService: secureSessionService,
        );
        addTearDown(bloc.close);

        final offersReceived = bloc.stream.firstWhere(
          (state) => state is BookingOffersReceived,
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
        await offersReceived.timeout(const Duration(milliseconds: 500));
        expect(bloc.activeBidSessionId, 'cancel-session-4');

        final recoveredRide = bloc.stream.firstWhere(
          (state) => state is BookingRideRecovered,
        );
        bloc.add(const CancelBookingEvent());
        final state = await recoveredRide.timeout(
          const Duration(milliseconds: 500),
        );

        expect(state, isA<BookingRideRecovered>());
        expect(bloc.activeBidSessionId, isNull);
        expect((state as BookingRideRecovered).rideId, 'ride-55');
        verify(() => secureSessionService.saveActiveRideId('ride-55'))
            .called(1);
      },
    );
  });
}
