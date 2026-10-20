import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/app/navigation/navigation_observer.dart';
import 'package:passenger/src/core/location/location_access_cubit.dart';
import 'package:passenger/src/core/location/location_access_state.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/auth/domain/repositories/session_repository.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/booking/booking_routes.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking_draft/booking_draft_cubit.dart';
import 'package:passenger/src/features/home/domain/entities/current_location.dart';
import 'package:passenger/src/features/home/domain/entities/home_data.dart';
import 'package:passenger/src/features/home/domain/repositories/current_location_repository.dart';
import 'package:passenger/src/features/home/domain/repositories/home_repository.dart';
import 'package:passenger/src/features/home/home_routes.dart';
import 'package:passenger/src/features/home/presentation/bloc/home/home_cubit.dart';
import 'package:passenger/src/features/home/presentation/bloc/public_driver_summary/public_driver_summary_cubit.dart';
import 'package:passenger/src/features/home/presentation/bloc/public_driver_summary/public_driver_summary_state.dart';
import 'package:passenger/src/features/home/presentation/pages/home_page.dart';
import 'package:passenger/src/features/home/presentation/widgets/recent_ride_history_preview.dart';
import 'package:passenger/src/features/ride_history/presentation/bloc/ride_history/ride_history_bloc.dart';
import 'package:passenger/src/features/ride_history/ride_history.dart';
import 'package:passenger/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:passenger/src/features/saved_places/presentation/bloc/saved_places_cubit.dart';
import 'package:passenger/src/features/saved_places/presentation/bloc/saved_places_state.dart';

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
  testWidgets(
    'search reopens after booking cancellation returns to retained Home',
    (tester) async {
      final locationRepository = _MockCurrentLocationRepository();
      final homeRepository = _MockHomeRepository();
      final homeCubit = HomeCubit(
        repository: homeRepository,
        currentLocationRepository: locationRepository,
      );
      final sessionBloc = SessionBloc(
        sessionRepository: _MockSessionRepository(),
      );
      final locationAccess = _MockLocationAccessCubit();
      final bookingBloc = _MockBookingBloc();
      final publicDrivers = _MockPublicDriverSummaryCubit();
      final history = _MockRideHistoryBloc();
      final savedPlaces = _MockSavedPlacesCubit();
      final draft = BookingDraftCubit();
      final lifecycle = AppLifecycleCoordinator();

      when(locationRepository.getCurrentLocation).thenAnswer(
        (_) async => const Ok(CurrentLocation(latitude: 7.8, longitude: 123.4)),
      );
      when(locationRepository.watchCurrentLocation)
          .thenAnswer((_) => const Stream.empty());
      when(
        () => homeRepository.loadHomeData(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
        ),
      ).thenAnswer(
        (_) async =>
            const Ok(HomeData(currentAddress: 'Pickup', recentLocations: [])),
      );
      when(() => locationAccess.state).thenReturn(const LocationAccessReady());
      when(() => bookingBloc.activeDriverSearch).thenReturn(null);
      when(() => publicDrivers.state)
          .thenReturn(const PublicDriverSummaryState());
      when(() => history.state).thenReturn(const RideHistoryInitial());
      when(() => savedPlaces.state).thenReturn(const SavedPlacesState());
      when(savedPlaces.loadPlaces).thenAnswer((_) async {});

      var searchVisits = 0;
      final router = GoRouter(
        initialLocation: '/home',
        observers: [passengerNavigationObserver],
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (_, _, shell) => shell,
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/home',
                    name: HomeRoutes.home,
                    builder: (_, _) => HomePage(
                      bookingBloc: bookingBloc,
                      lifecycleCoordinator: lifecycle,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/search',
            name: BookingRoutes.searchDestination,
            builder: (context, _) {
              searchVisits++;
              return Scaffold(
                body: TextButton(
                  onPressed: () =>
                      context.pushNamed(BookingRoutes.findingDriver),
                  child: const Text('Start booking'),
                ),
              );
            },
          ),
          GoRoute(
            path: '/finding',
            name: BookingRoutes.findingDriver,
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => context.goNamed(HomeRoutes.home),
                child: const Text('Cancel booking'),
              ),
            ),
          ),
        ],
      );
      addTearDown(() async {
        router.dispose();
        await homeCubit.close();
        await sessionBloc.close();
        await draft.close();
        await lifecycle.dispose();
      });
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<SessionBloc>.value(value: sessionBloc),
            BlocProvider<LocationAccessCubit>.value(value: locationAccess),
            BlocProvider<HomeCubit>.value(value: homeCubit),
            BlocProvider<BookingDraftCubit>.value(value: draft),
            BlocProvider<PublicDriverSummaryCubit>.value(value: publicDrivers),
            BlocProvider<RideHistoryBloc>.value(value: history),
            BlocProvider<SavedPlacesCubit>.value(value: savedPlaces),
          ],
          child: MaterialApp.router(
            theme: EasyRideTheme.main,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final homeState = tester.state(find.byType(HomePage));
      for (var attempt = 0; attempt < 2; attempt++) {
        await tester.tap(
          find.byWidgetPredicate(
            (widget) => widget is Hero && widget.tag == 'search_bar_field',
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Start booking'),
          findsOneWidget,
          reason: 'Search must open on attempt $attempt after returning Home',
        );
        await tester.tap(find.text('Start booking'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel booking'));
        await tester.pumpAndSettle();
        expect(tester.state(find.byType(HomePage)), same(homeState));
      }
      expect(searchVisits, greaterThanOrEqualTo(2));
    },
  );

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

    await tester.tap(find.text('Search Robinsons'));
    await tester.pumpAndSettle();

    expect(find.text('Active Ride in Progress'), findsOneWidget);
    expect(find.textContaining('Alex'), findsWidgets);
    expect(find.text('Resume Trip'), findsOneWidget);
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
      when(() => bookingBloc.state).thenReturn(const BookingInitial());
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
      expect(find.byType(RecentRideHistoryPreview), findsOneWidget);
      final previewWidget = tester.widget<RecentRideHistoryPreview>(
        find.byType(RecentRideHistoryPreview),
      );
      expect(previewWidget.rides.length, 2);
    },
  );

  testWidgets(
    'displays AppStatusBanner across the top safe area on error and dismisses on tap',
    (tester) async {
      final currentLocationRepository = _MockCurrentLocationRepository();
      final homeRepository = _MockHomeRepository();
      final bookingBloc = _MockBookingBloc();
      final locationAccessCubit = _MockLocationAccessCubit();
      final publicDriverSummaryCubit = _MockPublicDriverSummaryCubit();
      final rideHistoryBloc = _MockRideHistoryBloc();
      final savedPlacesCubit = _MockSavedPlacesCubit();
      final sessionRepository = _MockSessionRepository();
      final sessionStore = _MockPassengerSessionStore();
      final trackRepository = _MockTrackRepository();
      final lifecycleCoordinator = AppLifecycleCoordinator();

      final homeCubit = HomeCubit(
        repository: homeRepository,
        currentLocationRepository: currentLocationRepository,
      );
      final bookingDraftCubit = BookingDraftCubit();
      final sessionBloc = SessionBloc(sessionRepository: sessionRepository);

      final savedPlacesController =
          StreamController<SavedPlacesState>.broadcast();

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
      when(() => bookingBloc.activeDriverSearch).thenReturn(null);
      when(sessionStore.readActiveRideId).thenAnswer((_) async => null);
      when(() => locationAccessCubit.state)
          .thenReturn(const LocationAccessReady());
      when(() => locationAccessCubit.stream)
          .thenAnswer((_) => const Stream.empty());
      when(() => publicDriverSummaryCubit.state)
          .thenReturn(const PublicDriverSummaryState());
      when(() => publicDriverSummaryCubit.stream)
          .thenAnswer((_) => const Stream.empty());
      when(() => rideHistoryBloc.state)
          .thenReturn(const RideHistoryLoaded(past: [], upcoming: []));
      when(() => rideHistoryBloc.stream)
          .thenAnswer((_) => const Stream.empty());
      when(() => savedPlacesCubit.state)
          .thenReturn(const SavedPlacesState(places: [], isLoading: false));
      when(savedPlacesCubit.loadPlaces).thenAnswer((_) async {});
      when(() => savedPlacesCubit.stream)
          .thenAnswer((_) => savedPlacesController.stream);

      addTearDown(() async {
        await savedPlacesController.close();
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

      expect(find.byType(AppStatusBanner), findsNothing);

      savedPlacesController.add(
        const SavedPlacesState(
          places: [],
          isLoading: false,
          errorMessage: 'Could not load saved places.',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppStatusBanner), findsOneWidget);
      expect(find.text('Could not load saved places.'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);

      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      expect(find.byType(AppStatusBanner), findsNothing);
    },
  );

  testWidgets('blocks saved place shortcuts when an active ride exists', (
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
    when(() => savedPlacesCubit.state).thenReturn(
      const SavedPlacesState(
        isLoading: false,
        places: [
          SavedPlace(
            label: 'Work',
            iconName: 'briefcase',
            savedAddress: '100 Silicon Way',
            latitude: 37.39,
            longitude: -122.08,
          ),
        ],
      ),
    );
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

    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();

    expect(find.text('Active Ride in Progress'), findsOneWidget);
    expect(find.text('Resume Trip'), findsOneWidget);
  });
}
