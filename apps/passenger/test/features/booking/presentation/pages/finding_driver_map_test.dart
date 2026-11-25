import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mapbox_maps_flutter_platform_interface/mapbox_maps_flutter_platform_interface_internal.dart';
import 'package:maps/maps.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/core/location/live_map_bloc.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/booking/domain/entities/driver.dart';
import 'package:passenger/src/features/booking/domain/repositories/booking_repository.dart';
import 'package:passenger/src/features/booking/domain/repositories/driver_repository.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger/src/features/booking/presentation/bloc/nearby_drivers/nearby_drivers_cubit.dart';
import 'package:passenger/src/features/booking/presentation/pages/finding_driver_page.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';

class _Booking extends MockBloc<BookingEvent, BookingState>
    implements BookingBloc {}

class _Nearby extends MockCubit<NearbyDriversState>
    implements NearbyDriversCubit {}

class _Map extends MockBloc<LiveMapEvent, LiveMapState>
    implements LiveMapBloc {}

class _Profiles extends Mock implements DriverProfileRepository {}

class _DriverRepo extends Mock implements DriverRepository {}

class _BookingRepo extends Mock implements BookingRepository {}

class _SessionStore extends Mock implements SessionStore {}

final class _MapPlatform extends MapboxMapsFlutterPlatform {
  @override
  Widget buildView({
    required String styleUri,
    PlatformMapCreatedCallback? onMapCreated,
    ViewportState? viewport,
    ViewportTransition? viewportTransition,
    void Function(bool)? viewportTransitionCompletion,
    void Function(MapEvent)? onMapEvent,
    MapOptions? mapOptions,
    bool? textureView,
    // ignore: experimental_member_use
    required AndroidPlatformViewHostingMode androidHostingMode,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
    bool? isOpaque = true,
  }) => const SizedBox.expand();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'nearby availability adds, moves, and removes driver pins before any booking offer',
    (tester) async {
      registerFallbackValue(const ClearMapAnnotationsEvent());
      registerFallbackValue(const ResetBookingEvent());
      MapboxMapsFlutterPlatform.instance = _MapPlatform();
      final booking = _Booking();
      final nearby = _Nearby();
      final map = _Map();
      final updates = StreamController<NearbyDriversState>();
      whenListen(
        nearby,
        updates.stream,
        initialState: const NearbyDriversState(),
      );
      when(() => booking.state).thenReturn(const BookingInitial());
      when(() => booking.stream).thenAnswer((_) => const Stream.empty());
      when(() => booking.hasActiveDriverSearch).thenReturn(false);
      when(() => booking.activeDriverSearch).thenReturn(null);
      final snapshots = <ReplaceMapMarkersEvent>[];
      when(() => map.add(any())).thenAnswer((call) {
        final event = call.positionalArguments.first;
        if (event is ReplaceMapMarkersEvent) snapshots.add(event);
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<BookingBloc>.value(value: booking),
              BlocProvider<NearbyDriversCubit>.value(value: nearby),
              BlocProvider<LiveMapBloc>.value(value: map),
            ],
            child: FindingDriverPageContent(
              fare: 30,
              distance: '2 km',
              duration: '5 min',
              destination: const Place(
                id: 'destination',
                name: 'Destination',
                fullAddress: 'Destination',
                latitude: 14.7,
                longitude: 121,
              ),
              pickupLatitude: 14.6,
              pickupLongitude: 120.9,
              profileRepository: _Profiles(),
            ),
          ),
        ),
      );
      await tester.pump();
      verify(() => booking.add(any(that: isA<StartNearbyDriverSearchEvent>())))
          .called(1);
      Driver driverAt(double latitude) => Driver(
        id: 'nearby',
        name: 'Online driver',
        vehicleType: 'Tricycle',
        plateNumber: 'ABC 123',
        rating: 4.8,
        lat: latitude,
        lng: 120.91,
        distanceKm: 0.3,
        etaMinutes: 2,
        score: 1,
      );
      updates.add(
        NearbyDriversState(drivers: [driverAt(14.61)], hasLoaded: true),
      );
      await tester.pump();
      expect(snapshots, hasLength(1));
      expect(snapshots.last.markers, hasLength(2));
      expect(snapshots.last.markers.first.isOrigin, isTrue);
      expect(snapshots.last.markers.last.lat, 14.61);
      expect(snapshots.last.markers.last.label, isNull);
      expect(snapshots.last.markers.last.color, AppPalette.obsidian);
      expect(snapshots.last.markers.last.isOrigin, isFalse);
      updates.add(
        NearbyDriversState(drivers: [driverAt(14.62)], hasLoaded: true),
      );
      await tester.pump();
      expect(snapshots.last.markers.last.lat, 14.62);
      updates.add(const NearbyDriversState(drivers: [], hasLoaded: true));
      await tester.pump();
      expect(snapshots.last.markers, hasLength(1));
      expect(snapshots.last.markers.single.isOrigin, isTrue);
      await tester.pumpWidget(const SizedBox());
      await updates.close();
    },
  );

  testWidgets(
    'shows No drivers nearby after 15 seconds of empty search and retries cleanly',
    (tester) async {
      registerFallbackValue(const ClearMapAnnotationsEvent());
      MapboxMapsFlutterPlatform.instance = _MapPlatform();
      final driverRepo = _DriverRepo();
      final bookingRepo = _BookingRepo();
      final profiles = _Profiles();
      final sessionStore = _SessionStore();
      final lifecycle = AppLifecycleCoordinator();
      final map = _Map();
      final nearby = _Nearby();
      when(() => nearby.state).thenReturn(const NearbyDriversState());
      when(() => nearby.stream).thenAnswer((_) => const Stream.empty());
      when(() => map.add(any())).thenReturn(null);
      var returnDriver = false;
      const availableDriver = Driver(
        id: 'driver-1',
        name: 'Kuya Mario',
        vehicleType: 'Tricycle',
        plateNumber: 'TRI 101',
        rating: 4.9,
        lat: 14.61,
        lng: 120.91,
        distanceKm: 0.3,
        etaMinutes: 2,
        score: 1,
      );
      when(() => driverRepo.getNearbyDrivers(lat: 14.6, lng: 120.9))
          .thenAnswer((_) async => Ok(returnDriver ? [availableDriver] : []));
      final booking = BookingBloc(
        driverRepository: driverRepo,
        bookingRepository: bookingRepo,
        driverProfileRepository: profiles,
        secureSessionService: sessionStore,
        lifecycleCoordinator: lifecycle,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<BookingBloc>.value(value: booking),
              BlocProvider<NearbyDriversCubit>.value(value: nearby),
              BlocProvider<LiveMapBloc>.value(value: map),
            ],
            child: FindingDriverPageContent(
              fare: 30,
              distance: '2 km',
              duration: '5 min',
              destination: const Place(
                id: 'destination',
                name: 'Destination',
                fullAddress: 'Destination',
                latitude: 14.7,
                longitude: 121,
              ),
              pickupLatitude: 14.6,
              pickupLongitude: 120.9,
              profileRepository: profiles,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Looking nearby'), findsOneWidget);
      expect(find.text('No drivers nearby'), findsNothing);

      await tester.pump(const Duration(seconds: 14));
      expect(find.text('Looking nearby'), findsOneWidget);
      expect(find.text('No drivers nearby'), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('No drivers nearby'), findsOneWidget);
      expect(find.text('Retry search'), findsOneWidget);

      // Retrying search discovers drivers when they become available.
      returnDriver = true;
      await tester.tap(find.text('Retry search'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Kuya Mario'), findsOneWidget);
      expect(find.text('No drivers nearby'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      unawaited(booking.close());
      unawaited(lifecycle.dispose());
      await tester.pump();
    },
  );
}
