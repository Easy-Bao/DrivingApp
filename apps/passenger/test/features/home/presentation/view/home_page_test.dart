import 'package:bloc_test/bloc_test.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/auth/domain/repositories/session_repository.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking_draft/booking_draft_cubit.dart';
import 'package:passenger/src/features/home/domain/entities/current_location.dart';
import 'package:passenger/src/features/home/domain/entities/home_data.dart';
import 'package:passenger/src/features/home/domain/repositories/current_location_repository.dart';
import 'package:passenger/src/features/home/domain/repositories/home_repository.dart';
import 'package:passenger/src/features/home/presentation/bloc/home/home_cubit.dart';
import 'package:passenger/src/features/home/presentation/bloc/public_driver_summary/public_driver_summary_cubit.dart';
import 'package:passenger/src/features/home/presentation/bloc/public_driver_summary/public_driver_summary_state.dart';
import 'package:passenger/src/features/home/presentation/view/home_page.dart';
import 'package:passenger/src/features/home/presentation/widgets/recent_ride_history_preview_widget.dart';
import 'package:passenger/src/features/location/presentation/bloc/location_access/location_access_cubit.dart';
import 'package:passenger/src/features/location/presentation/bloc/location_access/location_access_state.dart';
import 'package:passenger/src/features/ride_history/presentation/bloc/ride_history/ride_history_bloc.dart';
import 'package:passenger/src/features/ride_history/ride_history.dart';
import 'package:passenger/src/features/saved_places/presentation/bloc/saved_places/saved_places_cubit.dart';
import 'package:passenger/src/features/saved_places/presentation/bloc/saved_places/saved_places_state.dart';
import 'package:passenger/src/infrastructure/session/passenger_session_store.dart';

class _MockCurrentLocationRepository extends Mock
    implements CurrentLocationRepository {}

class _MockHomeRepository extends Mock implements HomeRepository {}

class _MockBookingBloc extends MockBloc<BookingEvent, BookingState>
    implements BookingBloc {}

class _MockLocationAccessCubit extends MockCubit<LocationAccessViewState>
    implements LocationAccessCubit {}

class _MockPublicDriverSummaryCubit extends MockCubit<PublicDriverSummaryState>
    implements PublicDriverSummaryCubit {}

class _MockRideHistoryBloc extends MockBloc<RideHistoryEvent, RideHistoryState>
    implements RideHistoryBloc {}

class _MockSavedPlacesCubit extends MockCubit<SavedPlacesState>
    implements SavedPlacesCubit {}

class _MockSessionRepository extends Mock implements SessionRepository {}

class _MockPassengerSessionStore extends Mock
    implements PassengerSessionStore {}

class _MockTrackRepository extends Mock implements TrackRepository {}

void main() {
  testWidgets('syncs pickup location after session restoration completes', (
    tester,
  ) async {
    final currentLocationRepository = _MockCurrentLocationRepository();
    final homeRepository = _MockHomeRepository();
    final homeCubit = HomeCubit(
      repository: homeRepository,
      currentLocationRepository: currentLocationRepository,
    );
    final sessionBloc = SessionBloc(
      sessionRepository: _MockSessionRepository(),
    );
    final locationAccessCubit = _MockLocationAccessCubit();
    final bookingBloc = _MockBookingBloc();
    final publicDriverSummaryCubit = _MockPublicDriverSummaryCubit();
    final rideHistoryBloc = _MockRideHistoryBloc();
    final savedPlacesCubit = _MockSavedPlacesCubit();
    final bookingDraftCubit = BookingDraftCubit();
    final lifecycleCoordinator = AppLifecycleCoordinator();
    var homeRequestCount = 0;

    when(() => currentLocationRepository.getCurrentLocation()).thenAnswer(
      (_) async =>
          const Ok(CurrentLocation(latitude: 37.3861, longitude: -122.0839)),
    );
    when(() => currentLocationRepository.watchCurrentLocation())
        .thenAnswer((_) => const Stream.empty());
    when(
      () => homeRepository.loadHomeData(
        lat: any(named: 'lat'),
        lng: any(named: 'lng'),
      ),
    ).thenAnswer((_) async {
      homeRequestCount++;
      return Ok(
        HomeData(
          currentAddress: homeRequestCount == 1 ? '' : 'Mountain View',
          recentLocations: const [],
        ),
      );
    });
    when(() => locationAccessCubit.state)
        .thenReturn(const LocationAccessReady());
    when(() => bookingBloc.activeDriverSearch).thenReturn(null);
    when(() => publicDriverSummaryCubit.state)
        .thenReturn(const PublicDriverSummaryState());
    when(() => rideHistoryBloc.state).thenReturn(const RideHistoryInitial());
    when(() => savedPlacesCubit.state).thenReturn(const SavedPlacesState());
    when(savedPlacesCubit.loadPlaces).thenAnswer((_) async {});

    addTearDown(() async {
      await homeCubit.close();
      await sessionBloc.close();
      await bookingDraftCubit.close();
      await lifecycleCoordinator.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<SessionBloc>.value(value: sessionBloc),
            BlocProvider<LocationAccessCubit>.value(value: locationAccessCubit),
            BlocProvider<HomeCubit>.value(value: homeCubit),
            BlocProvider<BookingDraftCubit>.value(value: bookingDraftCubit),
            BlocProvider<PublicDriverSummaryCubit>.value(
              value: publicDriverSummaryCubit,
            ),
            BlocProvider<RideHistoryBloc>.value(value: rideHistoryBloc),
            BlocProvider<SavedPlacesCubit>.value(value: savedPlacesCubit),
          ],
          child: HomePage(
            bookingBloc: bookingBloc,
            lifecycleCoordinator: lifecycleCoordinator,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(homeRequestCount, 1);

    sessionBloc.add(
      const SessionAuthenticatedRequested(passengerId: 'passenger-1'),
    );
    await tester.pumpAndSettle();

    expect(homeRequestCount, 2);
    expect(find.text('Mountain View'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blocks destination search when an active ride is restored', (
    tester,
  ) async {
    final currentLocationRepository = _MockCurrentLocationRepository();
    final homeRepository = _MockHomeRepository();
    final homeCubit = HomeCubit(
      repository: homeRepository,
      currentLocationRepository: currentLocationRepository,
    );
    final sessionBloc = SessionBloc(
      sessionRepository: _MockSessionRepository(),
    );
    final locationAccessCubit = _MockLocationAccessCubit();
    final bookingBloc = _MockBookingBloc();
    final publicDriverSummaryCubit = _MockPublicDriverSummaryCubit();
    final rideHistoryBloc = _MockRideHistoryBloc();
    final savedPlacesCubit = _MockSavedPlacesCubit();
    final bookingDraftCubit = BookingDraftCubit();
    final lifecycleCoordinator = AppLifecycleCoordinator();

    when(() => currentLocationRepository.getCurrentLocation()).thenAnswer(
      (_) async =>
          const Ok(CurrentLocation(latitude: 37.3861, longitude: -122.0839)),
    );
    when(() => currentLocationRepository.watchCurrentLocation())
        .thenAnswer((_) => const Stream.empty());
    when(
      () => homeRepository.loadHomeData(
        lat: any(named: 'lat'),
        lng: any(named: 'lng'),
      ),
    ).thenAnswer(
      (_) async => const Ok(HomeData(currentAddress: '', recentLocations: [])),
    );
    when(() => locationAccessCubit.state)
        .thenReturn(const LocationAccessReady());
    when(() => bookingBloc.activeDriverSearch).thenReturn(null);
    when(() => publicDriverSummaryCubit.state)
        .thenReturn(const PublicDriverSummaryState());
    when(() => rideHistoryBloc.state).thenReturn(
      const RideHistoryLoaded(
        past: [],
        upcoming: [
          RideHistory(
            id: 'ride-1',
            pickup: 'Pickup',
            destination: 'Destination',
            pickupLat: 37.3861,
            pickupLng: -122.0839,
            destLat: 37.4,
            destLng: -122.1,
            date: '2026-09-16',
            price: '₱250',
            status: 'accepted',
            driverId: 'driver-1',
            driverName: 'Alex',
            vehiclePlate: 'ABC-123',
            vehicleType: 'Sedan',
          ),
        ],
      ),
    );
    when(() => savedPlacesCubit.state).thenReturn(const SavedPlacesState());
    when(savedPlacesCubit.loadPlaces).thenAnswer((_) async {});

    addTearDown(() async {
      await homeCubit.close();
      await sessionBloc.close();
      await bookingDraftCubit.close();
      await lifecycleCoordinator.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<SessionBloc>.value(value: sessionBloc),
            BlocProvider<LocationAccessCubit>.value(value: locationAccessCubit),
            BlocProvider<HomeCubit>.value(value: homeCubit),
            BlocProvider<BookingDraftCubit>.value(value: bookingDraftCubit),
            BlocProvider<PublicDriverSummaryCubit>.value(
              value: publicDriverSummaryCubit,
            ),
            BlocProvider<RideHistoryBloc>.value(value: rideHistoryBloc),
            BlocProvider<SavedPlacesCubit>.value(value: savedPlacesCubit),
          ],
          child: HomePage(
            bookingBloc: bookingBloc,
            lifecycleCoordinator: lifecycleCoordinator,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resume Trip'), findsOneWidget);
    await tester.tap(find.text('Search Robinsons'));
    await tester.pumpAndSettle();

    expect(find.text('Active Ride in Progress'), findsOneWidget);
    expect(find.textContaining('Alex'), findsWidgets);
    expect(find.text('Resume Trip'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'checks activeRideId in session store and queries active ride on launch',
    (tester) async {
      final currentLocationRepository = _MockCurrentLocationRepository();
      final homeRepository = _MockHomeRepository();
      final homeCubit = HomeCubit(
        repository: homeRepository,
        currentLocationRepository: currentLocationRepository,
      );
      final sessionBloc = SessionBloc(
        sessionRepository: _MockSessionRepository(),
      );
      final locationAccessCubit = _MockLocationAccessCubit();
      final bookingBloc = _MockBookingBloc();
      final publicDriverSummaryCubit = _MockPublicDriverSummaryCubit();
      final rideHistoryBloc = _MockRideHistoryBloc();
      final savedPlacesCubit = _MockSavedPlacesCubit();
      final bookingDraftCubit = BookingDraftCubit();
      final lifecycleCoordinator = AppLifecycleCoordinator();
      final sessionStore = _MockPassengerSessionStore();
      final trackRepository = _MockTrackRepository();

      when(() => currentLocationRepository.getCurrentLocation()).thenAnswer(
        (_) async =>
            const Ok(CurrentLocation(latitude: 37.3861, longitude: -122.0839)),
      );
      when(() => currentLocationRepository.watchCurrentLocation())
          .thenAnswer((_) => const Stream.empty());
      when(
        () => homeRepository.loadHomeData(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
        ),
      ).thenAnswer(
        (_) async => const Ok(
          HomeData(currentAddress: 'Mountain View', recentLocations: []),
        ),
      );
      when(() => locationAccessCubit.state)
          .thenReturn(const LocationAccessReady());
      when(() => bookingBloc.activeDriverSearch).thenReturn(null);
      when(() => publicDriverSummaryCubit.state)
          .thenReturn(const PublicDriverSummaryState());
      when(() => rideHistoryBloc.state).thenReturn(const RideHistoryInitial());
      when(() => savedPlacesCubit.state).thenReturn(const SavedPlacesState());
      when(savedPlacesCubit.loadPlaces).thenAnswer((_) async {});
      when(sessionStore.readActiveRideId)
          .thenAnswer((_) async => 'active-trip-99');
      when(() => trackRepository.fetchRideResult('active-trip-99')).thenAnswer(
        (_) async => const Ok(
          RideSnapshot(
            id: 'active-trip-99',
            status: 'accepted',
            pickupName: 'Origin St',
            dropoffName: 'Dest Ave',
          ),
        ),
      );

      addTearDown(() async {
        await homeCubit.close();
        await sessionBloc.close();
        await bookingDraftCubit.close();
        await lifecycleCoordinator.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: EasyRideTheme.main,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SessionBloc>.value(value: sessionBloc),
              BlocProvider<LocationAccessCubit>.value(
                value: locationAccessCubit,
              ),
              BlocProvider<HomeCubit>.value(value: homeCubit),
              BlocProvider<BookingDraftCubit>.value(value: bookingDraftCubit),
              BlocProvider<PublicDriverSummaryCubit>.value(
                value: publicDriverSummaryCubit,
              ),
              BlocProvider<RideHistoryBloc>.value(value: rideHistoryBloc),
              BlocProvider<SavedPlacesCubit>.value(value: savedPlacesCubit),
            ],
            child: HomePage(
              bookingBloc: bookingBloc,
              lifecycleCoordinator: lifecycleCoordinator,
              sessionService: sessionStore,
              trackRepository: trackRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      verify(sessionStore.readActiveRideId).called(1);
      verify(() => trackRepository.fetchRideResult('active-trip-99')).called(1);
    },
  );

  testWidgets(
    'deduplicates recent ride history entries with identical destinations',
    (tester) async {
      final currentLocationRepository = _MockCurrentLocationRepository();
      final homeRepository = _MockHomeRepository();
      final homeCubit = HomeCubit(
        repository: homeRepository,
        currentLocationRepository: currentLocationRepository,
      );
      final sessionBloc = SessionBloc(
        sessionRepository: _MockSessionRepository(),
      );
      final locationAccessCubit = _MockLocationAccessCubit();
      final bookingBloc = _MockBookingBloc();
      final publicDriverSummaryCubit = _MockPublicDriverSummaryCubit();
      final rideHistoryBloc = _MockRideHistoryBloc();
      final savedPlacesCubit = _MockSavedPlacesCubit();
      final bookingDraftCubit = BookingDraftCubit();
      final lifecycleCoordinator = AppLifecycleCoordinator();
      final sessionStore = _MockPassengerSessionStore();
      final trackRepository = _MockTrackRepository();

      when(() => currentLocationRepository.getCurrentLocation()).thenAnswer(
        (_) async =>
            const Ok(CurrentLocation(latitude: 37.3861, longitude: -122.0839)),
      );
      when(() => currentLocationRepository.watchCurrentLocation())
          .thenAnswer((_) => const Stream.empty());
      when(
        () => homeRepository.loadHomeData(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
        ),
      ).thenAnswer(
        (_) async => const Ok(
          HomeData(currentAddress: 'Mountain View', recentLocations: []),
        ),
      );
      when(() => locationAccessCubit.state)
          .thenReturn(const LocationAccessReady());
      when(() => locationAccessCubit.stream)
          .thenAnswer((_) => const Stream.empty());
      when(() => bookingBloc.state).thenReturn(BookingInitial());
      when(() => bookingBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => bookingBloc.hasActiveDriverSearch).thenReturn(false);
      when(() => bookingBloc.activeDriverSearch).thenReturn(null);
      when(() => publicDriverSummaryCubit.state)
          .thenReturn(const PublicDriverSummaryState());
      when(() => publicDriverSummaryCubit.stream)
          .thenAnswer((_) => const Stream.empty());
      when(() => savedPlacesCubit.state).thenReturn(const SavedPlacesState());
      when(() => savedPlacesCubit.stream)
          .thenAnswer((_) => const Stream.empty());
      when(savedPlacesCubit.loadPlaces).thenAnswer((_) async {});
      when(() => sessionStore.readActiveRideId()).thenAnswer((_) async => null);

      final duplicateRides = [
        const RideHistory(
          id: 'ride-1',
          pickup: 'Origin 1',
          destination: 'SM City',
          pickupLat: 7.82,
          pickupLng: 123.43,
          destLat: 7.83,
          destLng: 123.44,
          date: '2026-09-20',
          price: '₱100',
          status: 'completed',
          driverId: 'driver-1',
          driverName: 'Driver One',
          vehiclePlate: 'ABC 123',
          vehicleType: 'Car',
        ),
        const RideHistory(
          id: 'ride-2',
          pickup: 'Origin 2',
          destination: 'sm city',
          pickupLat: 7.82,
          pickupLng: 123.43,
          destLat: 7.83,
          destLng: 123.44,
          date: '2026-09-19',
          price: '₱100',
          status: 'completed',
          driverId: 'driver-2',
          driverName: 'Driver Two',
          vehiclePlate: 'DEF 456',
          vehicleType: 'Car',
        ),
        const RideHistory(
          id: 'ride-3',
          pickup: 'Origin 3',
          destination: 'City Hall',
          pickupLat: 7.82,
          pickupLng: 123.43,
          destLat: 7.84,
          destLng: 123.45,
          date: '2026-09-18',
          price: '₱120',
          status: 'completed',
          driverId: 'driver-3',
          driverName: 'Driver Three',
          vehiclePlate: 'GHI 789',
          vehicleType: 'Car',
        ),
      ];

      when(
        () => rideHistoryBloc.state,
      ).thenReturn(RideHistoryLoaded(past: duplicateRides, upcoming: const []));
      when(() => rideHistoryBloc.stream)
          .thenAnswer((_) => const Stream.empty());

      addTearDown(() async {
        await homeCubit.close();
        await sessionBloc.close();
        await bookingDraftCubit.close();
        await lifecycleCoordinator.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: EasyRideTheme.main,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<SessionBloc>.value(value: sessionBloc),
              BlocProvider<LocationAccessCubit>.value(
                value: locationAccessCubit,
              ),
              BlocProvider<HomeCubit>.value(value: homeCubit),
              BlocProvider<BookingDraftCubit>.value(value: bookingDraftCubit),
              BlocProvider<PublicDriverSummaryCubit>.value(
                value: publicDriverSummaryCubit,
              ),
              BlocProvider<RideHistoryBloc>.value(value: rideHistoryBloc),
              BlocProvider<SavedPlacesCubit>.value(value: savedPlacesCubit),
            ],
            child: HomePage(
              bookingBloc: bookingBloc,
              lifecycleCoordinator: lifecycleCoordinator,
              sessionService: sessionStore,
              trackRepository: trackRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SM City'), findsOneWidget);
      expect(find.text('City Hall'), findsOneWidget);
      expect(find.byType(RecentRideHistoryPreviewWidget), findsOneWidget);
      final previewWidget = tester.widget<RecentRideHistoryPreviewWidget>(
        find.byType(RecentRideHistoryPreviewWidget),
      );
      expect(previewWidget.rides.length, 2);
    },
  );
}
