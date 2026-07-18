import 'package:bloc_test/bloc_test.dart';
import 'package:core_models/core_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:passenger_app/src/features/booking/presentation/bloc/booking_event.dart';
import 'package:passenger_app/src/features/booking/presentation/bloc/booking_state.dart';
import 'package:passenger_services/passenger_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDriverRepo extends Mock implements DriverRepository {}

class MockBidSessionService extends Mock implements BidSessionService {}

class MockPassengerApiService extends Mock implements PassengerApiService {}

BookingBloc _makeBloc({
  required DriverRepository driverRepo,
  required BidSessionService bidService,
  required PassengerApiService apiService,
}) => BookingBloc(
  driverRepository: driverRepo,
  bidSessionService: bidService,
  apiService: apiService,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDriverRepo driverRepo;
  late MockBidSessionService bidService;
  late MockPassengerApiService apiService;

  setUp(() {
    driverRepo = MockDriverRepo();
    bidService = MockBidSessionService();
    apiService = MockPassengerApiService();
    SharedPreferences.setMockInitialValues({'passenger_id': 'pass-001'});
    // Default stub: cancelSession is always callable in cleanup paths.
    when(() => bidService.cancelSession()).thenAnswer((_) async {});
    when(() => bidService.setForeground(any())).thenAnswer((_) {});
    when(() => bidService.offersStream).thenAnswer(
      (_) => const Stream.empty(),
    );
    when(() => bidService.driverFoundStream).thenAnswer(
      (_) => const Stream.empty(),
    );
  });

  const mockDriver = DriverModel(
    id: 'driver-1',
    name: 'Pedro Santos',
    vehicleType: 'Bao Bao',
    plateNumber: 'ABC 1234',
    rating: 4.9,
    distanceKm: 0.5,
    lat: 7.829,
    lng: 123.435,
    etaMinutes: 5.0,
    score: 95.0,
  );

  group('BookingBloc — initial state', () {
    test('starts as BookingInitial', () async {
      final bloc = _makeBloc(
        driverRepo: driverRepo,
        bidService: bidService,
        apiService: apiService,
      );
      expect(bloc.state, isA<BookingInitial>());
      await bloc.close();
    });
  });

  group('BookingBloc — LocateNearestDriverEvent', () {
    blocTest<BookingBloc, BookingState>(
      'emits [FindingNearestDriver, NearestDriverFound(loading), NearestDriverFound(loaded)] on success',
      build: () {
        when(
          () => driverRepo.getNearbyDrivers(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => const Right([mockDriver]));
        when(
          () => apiService.fetchDriverStats(any()),
        ).thenAnswer((_) async => {'totalTrips': 42});
        when(
          () => apiService.fetchDriverReviews(any()),
        ).thenAnswer((_) async => []);
        return _makeBloc(
          driverRepo: driverRepo,
          bidService: bidService,
          apiService: apiService,
        );
      },
      act: (bloc) => bloc.add(
        const LocateNearestDriverEvent(pickupLat: 7.828, pickupLng: 123.434),
      ),
      expect: () => [
        isA<FindingNearestDriver>(),
        // intermediate state emitted before reviews are fetched
        isA<NearestDriverFound>().having(
          (s) => s.isLoadingReviews,
          'isLoadingReviews',
          true,
        ),
        // final state after reviews resolve
        isA<NearestDriverFound>().having(
          (s) => s.driver.id,
          'nearest driver id',
          'driver-1',
        ).having(
          (s) => s.isLoadingReviews,
          'isLoadingReviews',
          false,
        ),
      ],
    );

    blocTest<BookingBloc, BookingState>(
      'emits [FindingNearestDriver, BookingFailure] when no drivers found',
      build: () {
        when(
          () => driverRepo.getNearbyDrivers(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer((_) async => const Right([]));
        return _makeBloc(
          driverRepo: driverRepo,
          bidService: bidService,
          apiService: apiService,
        );
      },
      act: (bloc) => bloc.add(
        const LocateNearestDriverEvent(pickupLat: 7.828, pickupLng: 123.434),
      ),
      expect: () => [
        isA<FindingNearestDriver>(),
        isA<BookingFailure>().having(
          (s) => s.message,
          'failure message',
          'No drivers nearby.',
        ),
      ],
    );

    blocTest<BookingBloc, BookingState>(
      'emits [FindingNearestDriver, BookingFailure] on repository error',
      build: () {
        when(
          () => driverRepo.getNearbyDrivers(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
          ),
        ).thenAnswer(
          (_) async => const Left(ServerFailure('connection refused')),
        );
        return _makeBloc(
          driverRepo: driverRepo,
          bidService: bidService,
          apiService: apiService,
        );
      },
      act: (bloc) => bloc.add(
        const LocateNearestDriverEvent(pickupLat: 7.828, pickupLng: 123.434),
      ),
      expect: () => [
        isA<FindingNearestDriver>(),
        isA<BookingFailure>(),
      ],
    );
  });

  group('BookingBloc — CancelBookingEvent', () {
    blocTest<BookingBloc, BookingState>(
      'emits BookingCanceled and calls cancelSession on the bid service',
      build: () => _makeBloc(
        driverRepo: driverRepo,
        bidService: bidService,
        apiService: apiService,
      ),
      seed: () => FindingNearestDriver(),
      act: (bloc) => bloc.add(const CancelBookingEvent()),
      expect: () => [isA<BookingCanceled>()],
      verify: (_) => verify(() => bidService.cancelSession()).called(1),
    );
  });

  group('BookingBloc — UpdateOffersEvent', () {
    blocTest<BookingBloc, BookingState>(
      'emits BookingOffersReceived when current state is BookingSearching',
      build: () => _makeBloc(
        driverRepo: driverRepo,
        bidService: bidService,
        apiService: apiService,
      ),
      // UpdateOffersEvent only emits when in BookingSearching or BookingOffersReceived.
      seed: () => const BookingSearching(isDirect: false),
      act: (bloc) => bloc.add(
        const UpdateOffersEvent([
          {'driver_id': 'd1', 'proposed_fare': 80.0},
          {'driver_id': 'd2', 'proposed_fare': 75.0},
        ]),
      ),
      expect: () => [
        isA<BookingOffersReceived>().having(
          (s) => s.offers.length,
          'offers count',
          2,
        ),
      ],
    );

    blocTest<BookingBloc, BookingState>(
      'does not emit when current state is BookingInitial (event is silently dropped)',
      build: () => _makeBloc(
        driverRepo: driverRepo,
        bidService: bidService,
        apiService: apiService,
      ),
      act: (bloc) => bloc.add(
        const UpdateOffersEvent([
          {'driver_id': 'd1', 'proposed_fare': 80.0},
        ]),
      ),
      expect: () => [],
    );
  });
}
