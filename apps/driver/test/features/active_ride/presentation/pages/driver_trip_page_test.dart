import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:chat/chat.dart';
import 'package:design_system/design_system.dart';
import 'package:driver/src/core/session/session_store.dart';
import 'package:driver/src/features/active_ride/domain/services/ride_completion_handler.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/live_map/live_map_bloc.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_state.dart';
import 'package:driver/src/features/active_ride/presentation/pages/driver_trip_page.dart';
import 'package:driver/src/features/dashboard/dashboard_routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter_platform_interface/mapbox_maps_flutter_platform_interface_internal.dart';
import 'package:maps/maps.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _RideCubit extends MockCubit<RideState> implements RideFlowCubit {}

class _MapBloc extends MockBloc<LiveMapEvent, LiveMapState>
    implements LiveMapBloc {}

class _Session extends Mock implements SessionStore {}

class _Factory extends Mock implements ChatRepositoryFactory {}

class _CompletionHandler extends Mock implements RideCompletionHandler {}

class _Location extends GeolocatorPlatform {
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async => Position(
    latitude: 14.6,
    longitude: 120.9,
    timestamp: DateTime.now(),
    accuracy: 1,
    altitude: 0,
    altitudeAccuracy: 1,
    heading: 0,
    headingAccuracy: 1,
    speed: 0,
    speedAccuracy: 1,
  );
}

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
  }) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => onMapEvent?.call(
        MapLoadedEventData(
          timeInterval: EventTimeInterval(
            begin: DateTime.utc(2026),
            end: DateTime.utc(2026),
          ),
        ),
      ),
    );
    return const SizedBox.expand(key: ValueKey('persistent-trip-map'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('one map survives pickup, waiting, and transit before payment', (
    tester,
  ) async {
    final oldLocation = GeolocatorPlatform.instance;
    GeolocatorPlatform.instance = _Location();
    MapboxMapsFlutterPlatform.instance = _MapPlatform();
    addTearDown(() {
      GeolocatorPlatform.instance = oldLocation;
    });
    await LocationService.getCurrentPosition();
    final ride = _RideCubit();
    final map = _MapBloc();
    final session = _Session();
    final lifecycle = AppLifecycleCoordinator();
    final states = StreamController<RideState>();
    const pickup = RideFlowNavigatingToPickup(
      passengerName: 'Alex',
      pickupLatitude: 14.6,
      pickupLongitude: 120.9,
      destinationLatitude: 14.7,
      destinationLongitude: 121,
    );
    whenListen(ride, states.stream, initialState: pickup);
    when(() => map.state).thenReturn(const LiveMapInitial());
    when(() => map.stream).thenAnswer((_) => const Stream.empty());
    when(() => session.readDriverId()).thenAnswer((_) async => '');
    when(() => ride.activeRideId).thenReturn('trip');
    when(() => ride.activeBookingReference).thenReturn('reference');
    when(() => ride.canMarkPassengerNoShow).thenReturn(false);
    when(() => ride.passengerNoShowTimeRemaining).thenReturn(null);
    when(() => ride.refreshPassengerLocation()).thenAnswer((_) async {});
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => DriverTripPage(
            pickup: 'Pickup street',
            dropoff: 'Destination street',
            distance: 3,
            fare: 40,
            chatRepositoryFactory: _Factory(),
            sessionService: session,
            lifecycleCoordinator: lifecycle,
            rideCompletionHandler: _CompletionHandler(),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<RideFlowCubit>.value(value: ride),
          BlocProvider<LiveMapBloc>.value(value: map),
        ],
        child: MaterialApp.router(theme: AppTheme.main, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Head to pickup'), findsOneWidget);
    final mapElement = find
        .byKey(const ValueKey('persistent-trip-map'))
        .evaluate()
        .single;
    states.add(
      const RideFlowWaitingPassenger(
        passengerName: 'Alex',
        waitTimeSeconds: 20,
        pickupLatitude: 14.6,
        pickupLongitude: 120.9,
        destinationLatitude: 14.7,
        destinationLongitude: 121,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Start trip'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('persistent-trip-map')).evaluate().single,
      same(mapElement),
    );
    states.add(
      const RideFlowInTransit(
        passengerName: 'Alex',
        destinationLatitude: 14.7,
        destinationLongitude: 121,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Head to destination'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('persistent-trip-map')).evaluate().single,
      same(mapElement),
    );
    states.add(const RideFlowError('Transient failure'));
    await tester.pumpAndSettle();
    expect(find.text('Head to destination'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    await states.close();
    await lifecycle.dispose();
  });

  testWidgets(
    'displays trip completed fare summary before returning to dispatch',
    (tester) async {
      final oldLocation = GeolocatorPlatform.instance;
      GeolocatorPlatform.instance = _Location();
      MapboxMapsFlutterPlatform.instance = _MapPlatform();
      addTearDown(() {
        GeolocatorPlatform.instance = oldLocation;
      });
      await LocationService.getCurrentPosition();

      final ride = _RideCubit();
      final map = _MapBloc();
      final session = _Session();
      final completionHandler = _CompletionHandler();
      final lifecycle = AppLifecycleCoordinator();
      final states = StreamController<RideState>.broadcast();
      const inTransit = RideFlowInTransit(
        passengerName: 'Alex',
        destinationLatitude: 14.7,
        destinationLongitude: 121,
      );
      whenListen(ride, states.stream, initialState: inTransit);
      when(() => map.state).thenReturn(const LiveMapInitial());
      when(() => map.stream).thenAnswer((_) => const Stream.empty());
      when(() => session.readDriverId()).thenAnswer((_) async => '');
      when(() => ride.activeRideId).thenReturn('trip-42');
      when(() => ride.activePassengerName).thenReturn('Alex');
      when(() => ride.canMarkPassengerNoShow).thenReturn(false);
      when(() => ride.passengerNoShowTimeRemaining).thenReturn(null);
      when(() => ride.refreshPassengerLocation()).thenAnswer((_) async {});
      when(() => ride.reset()).thenAnswer((_) async {});
      when(() => completionHandler.afterRideCompleted(rideId: 'trip-42'))
          .thenAnswer((_) async {});

      final router = GoRouter(
        initialLocation: '/trip',
        routes: [
          GoRoute(
            path: '/dashboard',
            name: DashboardRoutes.dashboard,
            builder: (_, _) => const Scaffold(body: Text('Dispatch Home')),
          ),
          GoRoute(
            path: '/trip',
            builder: (_, _) => DriverTripPage(
              rideId: 'trip-42',
              pickup: 'Pickup street',
              dropoff: 'Destination street',
              distance: 3,
              fare: 40,
              chatRepositoryFactory: _Factory(),
              sessionService: session,
              lifecycleCoordinator: lifecycle,
              rideCompletionHandler: completionHandler,
            ),
          ),
        ],
      );
      addTearDown(() async {
        router.dispose();
        await states.close();
        await lifecycle.dispose();
      });

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<RideFlowCubit>.value(value: ride),
            BlocProvider<LiveMapBloc>.value(value: map),
          ],
          child: MaterialApp.router(theme: AppTheme.main, routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      states.add(const TripCompleted(fare: 85.5));
      await tester.pumpAndSettle();

      expect(find.text('Trip completed'), findsOneWidget);
      expect(find.text('₱85.50'), findsOneWidget);
      expect(find.text('Pickup street'), findsOneWidget);
      expect(find.text('Destination street'), findsOneWidget);
      expect(find.text('Alex'), findsOneWidget);
      expect(find.text('Back to dispatch'), findsOneWidget);

      await tester.tap(find.text('Back to dispatch'));
      await tester.pumpAndSettle();

      verify(() => ride.reset()).called(1);
      verify(() => completionHandler.afterRideCompleted(rideId: 'trip-42'))
          .called(1);
      expect(find.text('Dispatch Home'), findsOneWidget);
    },
  );

  testWidgets('requires confirmation before recording passenger no-show', (
    tester,
  ) async {
    final oldLocation = GeolocatorPlatform.instance;
    GeolocatorPlatform.instance = _Location();
    MapboxMapsFlutterPlatform.instance = _MapPlatform();
    addTearDown(() {
      GeolocatorPlatform.instance = oldLocation;
    });
    await LocationService.getCurrentPosition();

    final ride = _RideCubit();
    final map = _MapBloc();
    final session = _Session();
    final completionHandler = _CompletionHandler();
    final lifecycle = AppLifecycleCoordinator();
    final states = StreamController<RideState>.broadcast();
    const waiting = RideFlowWaitingPassenger(
      passengerName: 'Alex',
      waitTimeSeconds: 300,
      pickupLatitude: 14.6,
      pickupLongitude: 120.9,
      destinationLatitude: 14.7,
      destinationLongitude: 121,
    );
    whenListen(ride, states.stream, initialState: waiting);
    when(() => map.state).thenReturn(const LiveMapInitial());
    when(() => map.stream).thenAnswer((_) => const Stream.empty());
    when(() => session.readDriverId()).thenAnswer((_) async => '');
    when(() => ride.activeRideId).thenReturn('trip-no-show');
    when(() => ride.activePassengerName).thenReturn('Alex');
    when(() => ride.canMarkPassengerNoShow).thenReturn(true);
    when(() => ride.passengerNoShowTimeRemaining).thenReturn(Duration.zero);
    when(() => ride.markPassengerNoShow()).thenAnswer((_) async => true);
    when(() => ride.reset()).thenAnswer((_) async {});
    when(() => completionHandler.afterRideCompleted(rideId: 'trip-no-show'))
        .thenAnswer((_) async {});

    final router = GoRouter(
      initialLocation: '/trip',
      routes: [
        GoRoute(
          path: '/dashboard',
          name: DashboardRoutes.dashboard,
          builder: (_, _) => const Scaffold(body: Text('Dispatch Home')),
        ),
        GoRoute(
          path: '/trip',
          builder: (_, _) => DriverTripPage(
            rideId: 'trip-no-show',
            pickup: 'Pickup street',
            dropoff: 'Destination street',
            distance: 3,
            fare: 40,
            chatRepositoryFactory: _Factory(),
            sessionService: session,
            lifecycleCoordinator: lifecycle,
            rideCompletionHandler: completionHandler,
          ),
        ),
      ],
    );
    addTearDown(() async {
      router.dispose();
      await states.close();
      await lifecycle.dispose();
    });

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<RideFlowCubit>.value(value: ride),
          BlocProvider<LiveMapBloc>.value(value: map),
        ],
        child: MaterialApp.router(theme: AppTheme.main, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Passenger did not arrive'));
    await tester.pumpAndSettle();

    expect(find.text('Record passenger no-show?'), findsOneWidget);
    verifyNever(() => ride.markPassengerNoShow());

    await tester.tap(find.text('Keep waiting'));
    await tester.pumpAndSettle();
    verifyNever(() => ride.markPassengerNoShow());

    await tester.tap(find.text('Passenger did not arrive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm no-show'));
    await tester.pumpAndSettle();

    verify(() => ride.markPassengerNoShow()).called(1);
    expect(find.text('Passenger no-show recorded.'), findsOneWidget);
    expect(find.text('Dispatch Home'), findsOneWidget);
  });
}
