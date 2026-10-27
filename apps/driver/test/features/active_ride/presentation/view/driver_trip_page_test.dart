import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:design_system/design_system.dart';
import 'package:driver/src/features/active_ride/domain/services/ride_completion_handler.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/live_map/live_map_bloc.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_state.dart';
import 'package:driver/src/features/active_ride/presentation/view/driver_trip_page.dart';
import 'package:driver/src/features/chat/chat.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter_platform_interface/mapbox_maps_flutter_platform_interface_internal.dart';
import 'package:maps/maps.dart';
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
    when(() => map.state).thenReturn(LiveMapInitial());
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
            duration: '10 min',
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
}
